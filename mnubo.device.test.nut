// create a global variable called led, 
// and assign pin9 to it
led <- hardware.pin9;
 
// configure led to be a digital output
led.configure(DIGITAL_OUT);
 
function sendDeviceIdMessageToAgent()  {
    // Send a message to the server with the deviceId
    agent.send("deviceIdMessage", hardware.getdeviceid());
}
 
// test function to turn LED on or off
//  and send a message to the agent
function setLed(ledState) {
  server.log("Set LED: " + ledState);
  led.write(ledState);
  
  server.log("Sending \'DeviceId\' message to server.");
  sendDeviceIdMessageToAgent();
}
 
// register a test handler for "ping" messages from the agent
agent.on("ping", setLed);
