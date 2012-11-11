//http://www.codeproject.com/Articles/473828/Arduino-Csharp-and-serial-interface


#include <Wire.h>

#define LED_TURN_ON_TIMEOUT 200		//defines how long the LED stays powered on
#define LED_PIN 13					//Pin number on which the LED is connected

/*   OPERATION STATUS CONSTANTS                                   */
//MESSAGES
#define MSG_METHOD_SUCCESS 0                      //Code which is used when an operation terminated  successfully
#define MSG_SERIAL_CONNECTED 1                    //Code which is used to indicate that a new serial connection was established
//WARNINGS
#define WRG_NO_SERIAL_DATA_AVAIBLE 250            //Code indicates that no new data is avaible at the serial input buffer
//ERRORS
#define ERR_SERIAL_IN_COMMAND_NOT_TERMINATED -1   //Code used when command is empty




int iTmp102Address = 0x48;
int iDelay = 1000;
String readString;


void setup()
{
	pinMode(LED_PIN, OUTPUT);
	Serial.begin(9600);
	Wire.begin();
}

float getTemperature()
{
	Wire.requestFrom(iTmp102Address,2);

	byte MSB = Wire.read();
	byte LSB = Wire.read();

	int iTemperatureSum = ((MSB << 8) | LSB) >> 4;

	float fCelsius = iTemperatureSum*0.0625;
	return fCelsius;
}

int readSerialInputCommand(String *command)
{
  
  int operationStatus = MSG_METHOD_SUCCESS;//Default return is MSG_METHOD_SUCCESS reading data from com buffer.
  
  //check if serial data is available for reading
  if (Serial.available()) 
  {
	 char serialInByte;//temporary variable to hold the last serial input buffer character
	 
	 do
	 {//Read serial input buffer data byte by byte 
		 serialInByte = Serial.read();
		 *command = *command + serialInByte;//Add last read serial input buffer byte to *command pointer
	
	 }while(serialInByte != '#' && Serial.available());//until '#' comes up and serial data is avaible
   
	
	 if(((String)(*command)).indexOf('#') < 1) 
	 {
	   operationStatus = ERR_SERIAL_IN_COMMAND_NOT_TERMINATED;
	 }
  }
  else
  {//If not serial input buffer data is avaible, operationStatus becomes WRG_NO_SERIAL_DATA_AVAIBLE
	operationStatus = WRG_NO_SERIAL_DATA_AVAIBLE;
  }
  
  return operationStatus;
}

void loop()
{

	float fCelsius = getTemperature();
	Serial.println(fCelsius,4);

	String command = "";  //Used to store the latest received command
	int serialResult = 0; //return value for reading operation method on serial in put buffer
	serialResult = readSerialInputCommand(&command);

	if(serialResult == ERR_SERIAL_IN_COMMAND_NOT_TERMINATED)		//If the command format was invalid, the led is turned off for two seconds
	{
		digitalWrite(LED_PIN, HIGH);
		delay(2000);
		digitalWrite(LED_PIN, LOW);
	}
				
	if(serialResult == MSG_METHOD_SUCCESS)
	{	
		command = command.substring(0, command.length() - 1);		//removes "#" character at the end of the received command 
		char chTempDelay[command.length() + 1];						//translates string to int for delay function	
		command.toCharArray(chTempDelay, sizeof(chTempDelay));
		iDelay = atoi(chTempDelay); 
	}
	
	delay(iDelay); 
}


