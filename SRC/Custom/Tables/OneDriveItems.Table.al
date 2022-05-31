table 50002 "OneDrive Item"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    fields
    {
        field(1; id; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(2; driveId; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(3; parentId; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(4; name; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(5; isFile; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(6; webUrl; Text[250])
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

    procedure GetDriveItems(AccessToken: Text; driveID: Text)
    var
        JsonResponse: JsonObject;
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

        RequestMessage.SetRequestUri(StrSubstNo('https://graph.microsoft.com/v1.0/drives/%1/root/children', driveID));
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
                            if JDrive.Get('file', JToken) then
                                Rec.isFile := true;
                            if JDrive.Get('webUrl', JToken) then
                                Rec.webUrl := JToken.AsValue().AsText();
                            Rec.driveId := driveID;
                            if Rec.Insert() then;
                        end;

                    end;
                end;
    end;

    procedure DownloadItem(): Boolean
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestContent: HttpContent;
        ConnectorSetup: Record "Connector Setup";
        Stream: InStream;
    begin
        ConnectorSetup.Get();

        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', StrSubstNo('Bearer %1', ConnectorSetup.ReceiveAccessToken));

        RequestMessage.SetRequestUri(StrSubstNo('https://graph.microsoft.com/v1.0/drives/%1/items/%2/content', Rec.driveId, Rec.id));
        RequestMessage.Method := 'GET';

        if Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsSuccessStatusCode() then
                if ResponseMessage.Content.ReadAs(Stream) then begin
                    DownloadFromStream(Stream, 'Download File', '', '', Rec.name);
                    exit(true); //success
                end;

        exit(false); //fail
    end;

    procedure UploadItem(): Boolean
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestContent: HttpContent;
        ConnectorSetup: Record "Connector Setup";
        ResponseText: Text;
        Stream: InStream;
        FileName: Text;
    begin
        ConnectorSetup.Get();

        UploadIntoStream('Upload a file', '', '', FileName, Stream);

        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', StrSubstNo('Bearer %1', ConnectorSetup.ReceiveAccessToken));

        RequestMessage.SetRequestUri(StrSubstNo('https://graph.microsoft.com/v1.0/drives/%1/items/root:/%2:/content', Rec.driveId, FileName));
        RequestMessage.Method := 'PUT';

        RequestContent.WriteFrom(Stream);
        RequestMessage.Content := RequestContent;

        if Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsSuccessStatusCode() then
                exit(true); //success

        exit(false); //fail
    end;

    procedure CreateFolder(): Boolean
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestContent: HttpContent;
        ConnectorSetup: Record "Connector Setup";
        ResponseText: Text;
        EmptyObject: JsonObject;
        JsonBody: JsonObject;
        RequestText: Text;
    begin
        ConnectorSetup.Get();

        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', StrSubstNo('Bearer %1', ConnectorSetup.ReceiveAccessToken));

        RequestMessage.SetRequestUri(StrSubstNo('https://graph.microsoft.com/v1.0/sites/drives/%1/items/root/children', Rec.driveId));
        RequestMessage.Method := 'POST';

        JsonBody.Add('name', 'New Folder');
        JsonBody.Add('folder', EmptyObject);
        JsonBody.WriteTo(RequestText);
        RequestContent.WriteFrom(RequestText);

        RequestContent.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        if Client.Send(RequestMessage, ResponseMessage) then
            if ResponseMessage.IsSuccessStatusCode() then
                exit(true); //success


        ResponseMessage.Content.ReadAs(ResponseText);
        exit(false); //fail
    end;

}