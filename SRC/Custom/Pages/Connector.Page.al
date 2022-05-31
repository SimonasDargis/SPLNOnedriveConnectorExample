page 50000 Connector
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Connector Setup";
    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field(ClientID; Rec."Client ID")
                {
                    ApplicationArea = All;
                }
                field(ClientSecret; Rec."Client Secret")
                {
                    ApplicationArea = All;
                }
                field("Redirect URL"; Rec."Redirect URL")
                {
                    ApplicationArea = All;
                }
                field("Authorization URL Path"; Rec."Authorization URL")
                {
                    ApplicationArea = All;
                }
                field("Access Token URL Path"; Rec."Access Token URL")
                {
                    ApplicationArea = All;
                }
                field(Scope; Rec.Scope)
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
            action(GetToken)
            {
                ApplicationArea = All;
                Caption = 'Get Access Token';
                trigger OnAction()
                begin
                    if Rec.ReceiveAccessToken() <> '' then
                        Message('Access Token successfully updated.');
                end;
            }
            action(RefreshToken)
            {
                ApplicationArea = All;
                Caption = 'Refresh Access Token';
                trigger OnAction()
                var
                begin
                    if Rec.RefreshAccessToken() then
                        Message('Access Token successfully refreshed.');
                end;
            }
            action(ResetToken)
            {
                ApplicationArea = All;
                Caption = 'Reset Access Token';
                trigger OnAction()
                begin
                    Rec.ResetAccessToken();
                    Message('Access Token has been reset.');
                end;
            }
        }
    }
}