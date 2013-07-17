// This is an example of how to always present your callsign and other goodies on a VE
// Note that there is no known way to display the degree symbol as the char chart is different
// Also because of the VERY limited memory size on the Uno, this sketch had to be compressed
// from it's former glory.
// joey@stan4d.net 


#include <TVout.h>
#include <fontALL.h>
#include <PString.h>
#include <pollserial.h>
#include <TinyGPS.h>

TVout tv;


// You must use uart for this to work
// Create an instance of the TinyGPS object
pollserial pserial;
TinyGPS gps;

// This is where you declare prototypes for the functions that will be 
// using the TinyGPS library.
void getgps(TinyGPS &gps);

// Your callsign
const char callsign[] = "NV0N";

//TMP36 Pin Variables
//the analog pin the TMP36's Vout (sense) pin is connected to
//the resolution is 10 mV / degree centigrade 
//(500 mV offset) to make negative temperatures an option
const int temperaturePin = 0;

unsigned long lastDisplayTime = 0; // for delay

void setup()  {
  tv.begin(NTSC, 128, 98);
  tv.set_hbi_hook(pserial.begin(4800));
  initOverlay();
  tv.select_font(font6x8);
  tv.fill(0);
}


// Initialize ATMega registers for video overlay capability.
// Must be called after tv.begin().
void initOverlay() {
  TCCR1A = 0;
  // Enable timer1.  ICES0 is set to 0 for falling edge detection on input capture pin.
  TCCR1B = _BV(CS10);

  // Enable input capture interrupt
  TIMSK1 |= _BV(ICIE1);

  // Enable external interrupt INT0 on pin 2 with falling edge.
  EIMSK = _BV(INT0);
  EICRA = _BV(ISC11);
}

// Required to reset the scan line when the vertical sync occurs
ISR(INT0_vect) {
  display.scanLine = 0;
}


void loop() {

  // display data every 5 minutes for 30 seconds
  // 5 minutes = 300,000 
  // 30 seconds = 30,000

  lastDisplayTime = millis(); // set display time to now

  while((millis() - lastDisplayTime) < 30000) { // for the next 30 seconds

    // display callsign
    tv.select_font(font6x8);
    tv.print(0,0, callsign);  

    while(pserial.available()) {    // if there is data on the RX pin...
      if(gps.encode(pserial.read())) {     // if there is a new valid sentence...
        getgps(gps);         // then display GPS data
      }
    } // while
    tv.delay_frame(10); // flicker prevention
  } // while
  tv.fill(0); // we're done displaying so turn off the overlay
  delay(300000); // wait 5 minutes
} // loop


// The getgps function will get and print the values we want.
void getgps(TinyGPS &gps)
{

  char buffer[22];
  PString message(buffer, sizeof(buffer));
  float latitude, longitude;

  //  time, date, temp

  int year;
  byte month, day, hour, minute, second, hundredths;
  gps.crack_datetime(&year,&month,&day,&hour,&minute,&second,&hundredths);

  if (int(hour) < 10) 
    message += "0"; 

  message.print(int(hour));
  message += ":";
  if (int(minute) < 10) 
    message += "0";
  message.print(int(minute));
  message += " ";
  if (int(month) < 10) 
    message += "0";
  message.print(int(month));
  message += "/";
  if (int(day) < 10) 
    message += "0";
  message.print(int(day));
  message += " UTC ";

  // temperature
  // Fancy TMP36 calc which converts to Farenheit and then clips to a 2 digit degree
  int temperature = int(((((analogRead(temperaturePin) * .004882814) - .5) *100) *1.8) +32);

  message.print(temperature);
  message += "F";
  tv.select_font(font4x6);
  tv.print(0,75, message); 

  // we're going to reuse the buffer so we need to clear it
  message.begin();

  //  coords, alt

  gps.f_get_position(&latitude, &longitude);

  // let's process!
  message.print(latitude);
  message += " "; 
  message.print(longitude);
  message += " ";

  int altitude = int(gps.f_altitude() * 3.2808399); // meters to feet then drop decimal

  message.print(altitude);
  message += "F";

  tv.print(0,85, message);  
} // getgps



