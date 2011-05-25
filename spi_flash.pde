//#define DEBUG
//#define DEBUG_LOW

// SPI ports
#define CS    10
#define MOSI  11
#define MISO  12
#define SCLK  13

// opcodes
#define WREN  0x06 // write enable
#define WRDI  0x04 // write disable
#define WRSR  0x01 // write status register
#define RDID  0x9F // read identification
#define RDSR  0x05 // read status register
#define READ  0x03 // read
#define SE    0x20 // sector erase
#define BE    0xD8 // block erase
#define CE    0xC7 // chip erase
#define PP    0x02 // page program

// minimal performance timings
#define SECTOR_ERASE_TIME 300

// start and end addresses
#define LOW_ADDRESS  0x00000000
#define HIGH_ADDRESS 0x000fffff

// should be a divisor of the memory area size, we will read
#define BUFFER_SIZE 1024

// speed
#define SERIAL_SPEED 115200

void setup() {
  // this is just a dummy variable
  byte clr;

  Serial.begin(SERIAL_SPEED);

  pinMode(MISO, INPUT);

  pinMode(MOSI, OUTPUT);
  pinMode(SCLK, OUTPUT);
  pinMode(CS, OUTPUT);
  
  deselect_chip();

  // SPCR = 01010000
  //interrupt disabled,spi enabled,msb 1st,master,clk low when idle,
  //sample on leading edge of clk,system clock/4 rate (fastest)

#ifndef DEBUG

  SPCR = (1<<SPE) | (1<<MSTR) | (0<<SPR1) | (0<<SPR0);

  // clear the status and data registers
  clr = SPSR;
  clr = SPDR;

  delay(10);

#else // debug code

  #ifdef DEBUG_LOW
  digitalWrite(CS, LOW);
  digitalWrite(MOSI, LOW);
  digitalWrite(SCLK, LOW);
  #else
  digitalWrite(CS, HIGH);
  digitalWrite(MOSI, HIGH);
  digitalWrite(SCLK, HIGH);
  #endif
  
#endif

}

void loop() {
  
  byte incomingByte = 0;

#ifndef DEBUG
  
  if (Serial.available() > 0) {
    // read the incoming byte:
    incomingByte = Serial.read();
  
    switch (incomingByte) {
      case READ:
        readEeprom();
        break;
      case 0x20: // should be SE, but this doesn't work for some reason
        eraseSector(LOW_ADDRESS);
        break;
      default:
        Serial.write(incomingByte);
    }
  }
  
#endif

}

void readEeprom() {
  byte buffer[BUFFER_SIZE];
  unsigned long address;
  for (address = LOW_ADDRESS; address <= HIGH_ADDRESS; address = address + BUFFER_SIZE) {
    delay(100);
    readBuffer(address, buffer);
    Serial.write(buffer, BUFFER_SIZE);
  }
}

// read BUFFER_SIZE bytes starting at address
void readBuffer(unsigned long address, byte *buffer) {
  int data;
  int i;
  
  select_chip();
  
  //transmit read opcode
  spi_transfer(READ);

  spi_transfer((byte)(address>>16));
  spi_transfer((byte)(address>>8));
  spi_transfer((byte)(address));
  
  for (i = 0; i < BUFFER_SIZE; i++) {
    // get data byte; transfer dummy byte
    buffer[i] = spi_transfer(0xFF);
  }
  
  // release chip, signal transfer end
  deselect_chip();
} 

void eraseSector(unsigned long address) {
  select_chip();
  
  spi_transfer(WREN);
  spi_transfer(SE);
  
  spi_transfer((byte)(address>>16));
  spi_transfer((byte)(address>>8));
  spi_transfer((byte)(address));
  
  deselect_chip();
  
  delay(SECTOR_ERASE_TIME);
}

char spi_transfer(volatile char data) {
  // Start the transmission
  SPDR = data;
  
  while (!(SPSR & (1<<SPIF))) {
    // Wait for the end of the transmission
  };
  
  // return the received byte
  return SPDR;
}

void select_chip() {
  digitalWrite(CS, LOW);
}

void deselect_chip() {
  digitalWrite(CS, HIGH);
}
