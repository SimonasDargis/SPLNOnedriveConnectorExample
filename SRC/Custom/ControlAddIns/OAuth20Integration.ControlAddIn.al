controladdin "OAuth 2.0 Integration"
{
    Scripts = '.\SRC\Custom\ControlAddIns\OAuthIntegration.js';
    RequestedWidth = 0;
    RequestedHeight = 0;
    HorizontalStretch = false;
    VerticalStretch = false;

    procedure StartAuthorization(AuthRequestUrl: Text);
    event AuthorizationCodeRetrieved(AuthCode: Text; ReturnState: Text);
    event ControlAddInReady();
}
