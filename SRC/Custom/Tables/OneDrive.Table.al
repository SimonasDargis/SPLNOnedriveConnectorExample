table 50001 OneDrive
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    fields
    {
        field(1; id; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(2; name; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(3; description; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(4; webUrl; Text[250])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }

    procedure GetDrives(AccessToken: Text)
    var
        JToken: JsonToken;
        ConnectorSetup: Record "Connector Setup";
        Client: HttpClient;
        Headers: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestContent: HttpContent;
        ResponseText: Text;
        JResponse: JsonObject;
        JDriveItem: JsonToken;
        JDrive: JsonObject;
    begin
        ConnectorSetup.Get();

        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', StrSubstNo('Bearer %1', AccessToken));

        RequestMessage.SetRequestUri('https://graph.microsoft.com/v1.0/drives/');
        RequestMessage.Method := 'GET';

        if Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsSuccessStatusCode() then
                if ResponseMessage.Content.ReadAs(ResponseText) then begin
                    JResponse.ReadFrom(ResponseText);
                    if JResponse.Get('value', JToken) then begin
                        foreach JDriveItem in JToken.AsArray() do begin
                            JDrive := JDriveItem.AsObject();

                            Rec.Init();
                            if JDrive.Get('id', JToken) then
                                Rec.Id := JToken.AsValue().AsText();
                            if JDrive.Get('name', JToken) then
                                Rec.Name := JToken.AsValue().AsText();
                            if JDrive.Get('description', JToken) then
                                Rec.description := JToken.AsValue().AsText();
                            if JDrive.Get('webUrl', JToken) then
                                Rec.webUrl := JToken.AsValue().AsText();
                            if Rec.Insert() then;
                        end;
                    end;
                end;
    end;

}