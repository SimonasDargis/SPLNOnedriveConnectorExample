var w;
var invertvalID;

Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlAddInReady');

function StartAuthorization(url) {
    w = window.open(url, '_blank', 'width=972,height=904,location=no');
    invertvalID = window.setInterval(TimerTic, 1000);
}

function TimerTic() {
    var urlParams = new URLSearchParams(w.location.search);
    if (urlParams.has('code')) {
        window.clearInterval(invertvalID);
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AuthorizationCodeRetrieved', [urlParams.get('code'), urlParams.get('state')]);
        window.close();
    }
}
