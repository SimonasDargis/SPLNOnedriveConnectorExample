table 50000 "Connector Setup"
{
    Caption = 'Drive Connector Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Client ID"; Text[250])
        {
            Caption = 'Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Client Secret"; Text[250])
        {
            Caption = 'Client Secret';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Redirect URL"; Text[250])
        {
            Caption = 'Redirect URL';
        }
        field(5; Scope; Text[250])
        {
            Caption = 'Scope';
        }
        field(6; "Authorization URL"; Text[250])
        {
            Caption = 'Authorization URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Authorization URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Authorization URL");
            end;
        }
        field(7; "Access Token URL"; Text[250])
        {
            Caption = 'Access Token URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Access Token URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Access Token URL");
            end;
        }
        field(9; "Access Token"; Blob)
        {
            Caption = 'Access Token';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Refresh Token"; Blob)
        {
            Caption = 'Refresh Token';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Authorization Time"; DateTime)
        {
            Caption = 'Authorization Time';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Expires In"; Integer)
        {
            Caption = 'Expires In';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(15; "Ext. Expires In"; Integer)
        {
            Caption = 'Ext. Expires In';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    //RECEIVE ACCESS TOKEN
    //Checks if authorization time isn't expired
    //If expired - use RefreshAccessToken
    //If valid - do nothing
    //Returns a text variant of the access token so that it can be used later for requests
    procedure ReceiveAccessToken(): Text
    var
        AuthCode: Text;
        ElapsedSecs: Integer;
    begin
        if (Rec."Authorization Time" <> 0DT) then begin
            ElapsedSecs := Round((CurrentDateTime() - Rec."Authorization Time") / 1000, 1, '>');
            if ElapsedSecs >= Rec."Expires In" then
                Rec.RefreshAccessToken();
        end else begin
            AuthCode := Rec.GetAuthorizationCode();
            Rec.GetAccessToken(AuthCode);
        end;
        exit(AccessTokenToText());
    end;

    //GET AUTHORIZATION CODE
    //Runs an authorization page to receive an authorization code
    procedure GetAuthorizationCode() AuthorizationCode: Text
    var
        AuthURL: Text;
        DotNetUriBuilder: Codeunit Uri;
        OAuth2Dialog: Page OAuth2Dialog;
        State: text;
    begin
        State := Format(CreateGuid(), 0, 4);

        AuthURL := Rec."Authorization URL" + '?' +
                    'client_id=' + DotNetUriBuilder.EscapeDataString(Rec."Client ID") +
                    '&redirect_uri=' + DotNetUriBuilder.EscapeDataString(Rec."Redirect URL") +
                    '&state=' + DotNetUriBuilder.EscapeDataString(State) +
                    '&scope=' + DotNetUriBuilder.EscapeDataString(Rec.Scope) +
                    '&response_type=code';

        OAuth2Dialog.SetOAuth2Properties(AuthURL, State);
        OAuth2Dialog.RunModal();

        AuthorizationCode := OAuth2Dialog.GetAuthCode();

        if AuthorizationCode = '' then
            Error('ERROR: Authorization code is invalid.');
    end;

    procedure GetAccessToken(AuthCode: Text): Boolean
    var
        DotNetUriBuilder: Codeunit Uri;
        ContentText: Text;
        ResponseText: Text;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        JAccessToken: JsonObject;
        Success: Boolean;
        JToken: JsonToken;
        Property: Text;
        OStream: OutStream;
        ElapsedSecs: Integer;
    begin
        Rec."Authorization Time" := CurrentDateTime();

        ContentText := 'grant_type=authorization_code' +
                                '&code=' + AuthCode +
                                '&redirect_uri=' + DotNetUriBuilder.EscapeDataString(Rec."Redirect URL") +
                                '&client_id=' + DotNetUriBuilder.EscapeDataString(Rec."Client ID") +
                                '&client_secret=' + DotNetUriBuilder.EscapeDataString(Rec."Client Secret");

        Content.WriteFrom(ContentText);
        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        Request.Method := 'POST';
        Request.SetRequestUri(Rec."Access Token URL");
        Request.Content(Content);

        if Client.Send(Request, Response) then
            if Response.IsSuccessStatusCode() then
                if Response.Content.ReadAs(ResponseText) then
                    Success := JAccessToken.ReadFrom(ResponseText);

        if Success then begin
            foreach Property in JAccessToken.Keys() do begin
                JAccessToken.Get(Property, JToken);
                case Property of
                    'token_type',
                    'scope':
                        ;
                    'expires_in':
                        Rec."Expires In" := JToken.AsValue().AsInteger();
                    'ext_expires_in':
                        Rec."Ext. Expires In" := JToken.AsValue().AsInteger();
                    'access_token':
                        begin
                            Rec."Access Token".CreateOutStream(OStream, TextEncoding::UTF8);
                            OStream.WriteText(JToken.AsValue().AsText());
                        end;
                    'refresh_token':
                        begin
                            Rec."Refresh Token".CreateOutStream(OStream, TextEncoding::UTF8);
                            OStream.WriteText(JToken.AsValue().AsText());
                        end;
                    else
                        Error('Invalid Access Token Property %1, Value:  %2', Property, JToken.AsValue().AsText());
                end;
            end;
            Rec.Modify();
            Commit();
        end;
        exit(Success);
    end;

    procedure AccessTokenToText(): Text
    var
        IStream: InStream;
        Buffer: TextBuilder;
        Line: Text;
    begin
        Rec.CalcFields("Access Token");
        if Rec."Access Token".HasValue then begin
            Rec."Access Token".CreateInStream(IStream, TextEncoding::UTF8);
            while not IStream.EOS do begin
                IStream.ReadText(Line, 1024);
                Buffer.Append(Line);
            end;
        end;

        exit(Buffer.ToText())
    end;

    procedure RefreshAccessToken(): Boolean
    var
        RefreshToken: Text;
        DotNetUriBuilder: Codeunit Uri;
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        ContentText: Text;
        ResponseText: Text;
        JToken: JsonToken;
        Property: Text;
        OStream: OutStream;
        JAccessToken: JsonObject;
        Success: Boolean;
    begin
        RefreshToken := RefreshTokenToText();
        if RefreshToken = '' then
            exit;

        Rec."Authorization Time" := CurrentDateTime();

        ContentText := 'grant_type=refresh_token' +
            '&refresh_token=' + DotNetUriBuilder.EscapeDataString(RefreshToken) +
            '&redirect_uri=' + DotNetUriBuilder.EscapeDataString(Rec."Redirect URL") +
            '&client_id=' + DotNetUriBuilder.EscapeDataString(Rec."Client ID") +
            '&client_secret=' + DotNetUriBuilder.EscapeDataString(Rec."Client Secret");
        Content.WriteFrom(ContentText);

        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        Request.Method := 'POST';
        Request.SetRequestUri(Rec."Access Token URL");
        Request.Content(Content);

        if Client.Send(Request, Response) then
            if Response.IsSuccessStatusCode() then
                if Response.Content.ReadAs(ResponseText) then
                    Success := JAccessToken.ReadFrom(ResponseText);

        if Success then begin
            foreach Property in JAccessToken.Keys() do begin
                JAccessToken.Get(Property, JToken);
                case Property of
                    'token_type',
                    'scope':
                        ;
                    'expires_in':
                        Rec."Expires In" := JToken.AsValue().AsInteger();
                    'ext_expires_in':
                        Rec."Ext. Expires In" := JToken.AsValue().AsInteger();
                    'access_token':
                        begin
                            Rec."Access Token".CreateOutStream(OStream, TextEncoding::UTF8);
                            OStream.WriteText(JToken.AsValue().AsText());
                        end;
                    'refresh_token':
                        begin
                            Rec."Refresh Token".CreateOutStream(OStream, TextEncoding::UTF8);
                            OStream.WriteText(JToken.AsValue().AsText());
                        end;
                    else
                        Error('Invalid Access Token Property %1, Value:  %2', Property, JToken.AsValue().AsText());
                end;
            end;
            Rec.Modify();
            Commit();
        end;
        exit(Success);
    end;

    local procedure RefreshTokenToText(): Text
    var
        IStream: InStream;
        Buffer: TextBuilder;
        Line: Text;
    begin
        Rec.CalcFields("Refresh Token");
        if Rec."Refresh Token".HasValue then begin
            Rec."Refresh Token".CreateInStream(IStream, TextEncoding::UTF8);
            while not IStream.EOS do begin
                IStream.ReadText(Line, 1024);
                Buffer.Append(Line);
            end;
        end;

        exit(Buffer.ToText())
    end;

    procedure ResetAccessToken()
    begin
        Rec."Authorization Time" := 0DT;
        Clear("Access Token");
        Clear("Refresh Token");
        Modify();
    end;

}