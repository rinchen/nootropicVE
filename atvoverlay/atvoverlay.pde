// This is an example of how to always present your callsign on a VE
// It can be modified with a delay to show it every 10 minutes
// joey@stan4d.net 

#include <TVout.h>
#include <fontALL.h>

TVout tv;
char message[] = "NV0N BCARES";

void setup()  {
  tv.begin(0);
  initOverlay();
  tv.select_font(font8x8ext);
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
  tv.print(28,0, message);      // top
  //   tv.print(28,40, message);  // center
  //   tv.print(28,78, message);  // bottom
  //   delay(1000);               //delay for reading
  //   tv.fill(0);                // clear
  //   delay(10000);              //delay between showing callsign

}



