page 50003 "OneDrive Items List"
{
    PageType = List;
    SourceTable = "OneDrive Item";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Name; Rec.name)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        if Rec.isFile then
                            Rec.DownloadItem();
                    end;
                }
                field(webUrl; Rec.webUrl)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UploadFile)
            {
                ApplicationArea = All;
                Caption = 'Upload file';
                trigger OnAction()
                begin
                    if Rec.UploadItem() then begin
                        UpdateDriveItems();
                    end;
                end;
            }
            action(CreateFolder)
            {
                ApplicationArea = All;
                Caption = 'Create folder';
                trigger OnAction()
                begin
                    if Rec.CreateFolder then begin
                        UpdateDriveItems();
                    end;
                end;
            }
        }
    }

    procedure SetDrive(DriveID: Text)
    var
    begin
        CurrDriveID := DriveID;
    end;

    local procedure UpdateDriveItems()
    var
        ConnectorSetup: Record "Connector Setup";
    begin
        Rec.Reset();
        ConnectorSetup.Get();
        Rec.GetDriveItems(ConnectorSetup.ReceiveAccessToken(), CurrDriveID);
        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    begin
        UpdateDriveItems();
    end;

    var
        CurrDriveID: Text;
}