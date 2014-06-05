/**************************************************************************
 * 'Mnubo' class definition.
 * it contains functions that can be used to send data from
 * electricimp agent to mnubo cloud.
 * 
 * note that this file also contains some 'test' code (strongly inspired
 * from the electricimp 'helloworld' example)
 *
*************************************************************************/

// Log the URLs we need
server.log("TEST: Turn LED On: " + http.agenturl() + "?led=1");
server.log("TEST: Turn LED Off: " + http.agenturl() + "?led=0");

const CLIENT_ID = "_CONFIGURE_clientid_HERE_";
const CLIENT_CONSUMER_KEY = "_CONFIGURE_consumerkey_HERE_"; 
const CLIENT_CONSUMER_SECRET = "_CONFIGURE_consumersecret_HERE_";

class Mnubo {
    
    _baseUrl = "https://mnuboserver/";
    _clientId = null;
    _clientConsumerKey = null;
    _clientConsumerSecret = null;
    _bearerAccessToken = null;
    
    _deviceId = null;
    
    constructor (aClientId, aConsumerKey, aConsumerSecret, aAccessToken) {
        this._clientId = aClientId;
        this._clientConsumerKey = aConsumerKey;
        this._clientConsumerSecret = aConsumerSecret;
        this._bearerAccessToken = aAccessToken;
    }
    
    function setDeviceId(aDeviceId) {
        this._deviceId = aDeviceId;
    }
    
    /**************************************************************************
     * Function: sendHTTPGetAuthToken
     * Desc:     Get Authentication Token for posting objects and sample data
     *             to mnubo cloud
     * Params:   None
     * Returns:  None - sets token value in object member var
     *************************************************************************/
    function sendHTTPGetAuthToken() 
    { 
        try 
        {
            local url = this._baseUrl + "/tokens/1";
            local argString = http.urlencode({clientid = this._clientId});
            local web_URL = url + "?" + argString;

            //calculate basic auth token
            local basicToken = http.base64encode(this._clientConsumerKey + ":" + this._clientConsumerSecret);
            local extraHeaders = { "Authorization" : "Basic " + basicToken };
            local request = http.get(web_URL, extraHeaders);
            local response = request.sendsync();
            //server.log("DEBUG: RESPONSE Code: " + response.statuscode + ". Body: " + response.body);
            
            local databody = http.jsondecode(response.body);
            
            if ("access_token" in databody) {
                server.log("DEBUG: bearer access token = <" + databody.access_token + ">");
                this._bearerAccessToken = databody.access_token; 
            }
            else {
                server.log("ERROR agent: No access token found in response." )
            }
        }
        catch (ex)
        {
            server.log("ERROR agent: " + ex );
        }
    }

    /**************************************************************************
     * Function: sendHTTPPostSample
     * Desc:     Send Sample to Cloud platform 
     *           (note that the object must previously have been created).
     * Params:   JSON formated data sample
     * Returns:  None 
     *************************************************************************/
    function sendHTTPPostSample(myJSONsample) 
    { 
        if (this._bearerAccessToken == null) {
            server.log("ERROR: Bearer token not set.");
            return;
        }
        try 
        {
            local url = this._baseUrl + "/objwrite/1/objects/" + this._deviceId + "/samples";
            local argString = http.urlencode({idtype = "deviceid", clientid = this._clientId});
            local web_URL = url + "?" + argString;

            // send request with a JSON payload      
            local extraHeaders = { "Content-Type":"application/json", "Authorization" : "Bearer " + this._bearerAccessToken };
            local request = http.post(web_URL, extraHeaders, myJSONsample);
            local response = request.sendsync();
            //server.log("DEBUG RESPONSE Code: " + response.statuscode + ". Body: " + response.body);
        }
        catch (ex)
        {
            server.log("ERROR agent :" + ex );
        }
    }
    
     /**************************************************************************
     * Function: sendHTTPPostObject
     * Desc:     Create Object in mnubo cloud platform 
     *           (note that ObjectModel must previously have been created).
     * Params:   JSON formated object data
     * Returns:  None 
     *************************************************************************/
    function sendHTTPPostObject(myJSONobject) 
    { 
        if (this._bearerAccessToken == null) {
            server.log("ERROR: Bearer token not set.");
            return;
        }
        try 
        {
            local url = this._baseUrl + "/objwrite/1/objects";
            local argString = http.urlencode({updateifexists = 1, clientid = this._clientId});
            local web_URL = url + "?" + argString;

            // Send request with a JSON payload
            local extraHeaders = { "Content-Type":"application/json", "Authorization" : "Bearer " + this._bearerAccessToken };
            local request = http.post(web_URL, extraHeaders, myJSONobject);
            local response = request.sendsync();
            //server.log("DEBUG RESPONSE Code: " + response.statuscode + ". Body: " + response.body);
        }
        catch (ex)
        {
            server.log("ERROR agent :" + ex );
        }
    }
    
    
    /**************************************************************************
     * Private Test function...
     * Desc:     test handler used to receive HTTP commands and send message to
     *           device.  
     *************************************************************************/
    function test_httpRequestHandler(request, response) {
        try {
            // check if the user sent led as a query parameter
            if ("led" in request.query) {
      
                // if they did, and led=1.. set our variable to 1 
                if (request.query.led == "1" || request.query.led == "0") {
                    // convert the led query parameter to an integer
                    local ledState = request.query.led.tointeger();
    
                    // send "led" message to device, and send ledState as the data
                    device.send("ping", ledState); 
                }
            }
            // send a response back saying everything was OK.
            response.send(200, "OK");
        } catch (ex) {
            response.send(500, "Internal Server Error: " + ex);
        }
    }
}

/**************************************************************************
* Private Test function...
* Desc:  function called with a message is received from a device.
*        this function sends a sequence of test/example messages
*        to mnubo cloud.   
*************************************************************************/
function test_HandleDeviceIdMessage(aDeviceId)
{
    server.log("DEBUG: just received message from Device Id:" + aDeviceId);
    
    // get Auth token
    mnubo.sendHTTPGetAuthToken();
    
    mnubo.setDeviceId(aDeviceId);
    
    // create object example
    mnubo.sendHTTPPostObject("{ \"activate\" : \"yes\", \"deviceid\" : \"" + aDeviceId + "\"," +
                             "  \"model_name\" : \"mnubo.helloWorld\"," +
                             "  \"attributes\" : [ { \"category\" : \"example\", \"name\" : \"software_version\", \"value\" : \"7.1.1\"} ] }");
 
    // post sample example
    mnubo.sendHTTPPostSample("{ \"samples\" : [ { \"name\" : \"app_event\", \"value\" : { \"event\" : \"use\", \"version\" : \"16.12\" } } ] }");

}


mnubo <- Mnubo(CLIENT_ID, CLIENT_CONSUMER_KEY, CLIENT_CONSUMER_SECRET, null);

// When we get a message from the device, call mnubo cloud()
device.on("deviceIdMessage", test_HandleDeviceIdMessage); 
 
// register the HTTP handler
http.onrequest(mnubo.test_httpRequestHandler);
