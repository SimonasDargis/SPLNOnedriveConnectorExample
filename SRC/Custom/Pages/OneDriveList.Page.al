page 50002 "OneDrive List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = OneDrive;
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
                    var
                        OneDriveItems: Page "OneDrive Items List";
                    begin
                        OneDriveItems.SetDrive(Rec.id);
                        OneDriveItems.RunModal();
                    end;
                }
                field(description; Rec.description)
                {
                    ApplicationArea = All;
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
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin

                end;
            }
        }
    }


    trigger OnOpenPage()
    var
        ConnectorSetup: Record "Connector Setup";
    begin
        ConnectorSetup.Get();
        Rec.GetDrives(ConnectorSetup.ReceiveAccessToken());
        CurrPage.Update(false);
    end;

}