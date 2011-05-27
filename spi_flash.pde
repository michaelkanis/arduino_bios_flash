//#define DEBUG
#define DEBUG_LOW

// SPI ports
#define CS    10
#define MOSI  11
#define MISO  12
#define SCLK  13

// opcodes
#define WREN 0x06 // write enable
#define WRDI 0x04 // write disable
#define WRSR 0x01 // write status register
#define REMS 0x90 // read identification
#define RDID 0x9F // read identification
#define RDSR 0x05 // read status register
#define READ 0x03 // read
#define SCTE 0x20 // sector erase
#define BLKE 0xD8 // block erase
#define CHPE 0xC7 // chip erase
#define PAPR 0x02 // page program

// we shift this byte to the SPDR in order to receive a byte from the chip
#define DUMMY 0x00

// minimal performance timings
#define SECTOR_ERASE_TIME 300
#define BLOCK_ERASE_TIME 2000
#define CHIP_ERASE_TIME 15000
#define PAGE_PROGRAM_TIME 5
#define WRITE_STATUS_REGISTER_TIME 100

// start and end addresses
#define LOW_ADDRESS  0x00000000
#define HIGH_ADDRESS 0x00000fff

// should be a divisor of the memory area size, we will read
// this could be higher than 256, but then some terminal programs
// on my PC lose bytes, it seems
#define BUFFER_SIZE 256

// speed
#define SERIAL_SPEED 115200

// this is just a dummy variable
byte clr;

void setup() {

  Serial.begin(SERIAL_SPEED);

  pinMode(MISO, INPUT);

  pinMode(MOSI, OUTPUT);
  pinMode(SCLK, OUTPUT);
  pinMode(CS, OUTPUT);
  
  deselect_chip();

  // SPCR = 01010011
  //interrupt disabled,spi enabled,msb 1st,master,clk low when idle,
  //sample on leading edge of clk, 250 kHz rate (slowest)

#ifndef DEBUG

  SPCR = (1<<SPE) | (1<<MSTR) | (1<<SPR1) | (1<<SPR0);

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
      case SCTE:
        eraseSector(LOW_ADDRESS);
        break;
      case BLKE:
        eraseBlock(LOW_ADDRESS);
        break;
      case CHPE:
        eraseChip();
        break;
      case RDSR:
        readStatus();
        break;
      case REMS:
        readManufacturerId();
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
    readBuffer(address, buffer);
    Serial.write(buffer, BUFFER_SIZE);
  }
}

// read BUFFER_SIZE bytes starting at address
void readBuffer(unsigned long address, byte *buffer) {
  int i;
  
  select_chip();
  
  delay(150);
  
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

void readStatus() {
  byte statusRegister;
  
  select_chip();
  spi_transfer(RDSR);
  statusRegister = spi_transfer(DUMMY);
  Serial.write(statusRegister);
  
  deselect_chip();
}

void readManufacturerId() {
  byte data;
  
  select_chip();
  
  spi_transfer(REMS);

  // 2 dummy bytes
  spi_transfer(DUMMY);
  spi_transfer(DUMMY);

  // 0x00 will output the manufacturer's ID first; 0x01 will output device ID first
  spi_transfer(0X00);

  // 1 byte manufacturer ID
  Serial.write(spi_transfer(DUMMY));

  // 1 byte device ID
  Serial.write(spi_transfer(DUMMY));
  
  deselect_chip();
}

void eraseSector(unsigned long address) {
  readStatus();
  enableWrite();
  readStatus();
  
  select_chip();
  
  spi_transfer(SCTE);
  
  spi_transfer((byte)(address>>16));
  spi_transfer((byte)(address>>8));
  spiWrite((byte)(address));
  deselect_chip();

  //Serial.write(spiRead());

  readStatus();

  delay(SECTOR_ERASE_TIME);
  
  readStatus();
}

void eraseBlock(unsigned long address) {
  readStatus();
  enableWrite();
  readStatus();
  
  select_chip();
  
  spi_transfer(BLKE);
  
  spi_transfer((byte)(address>>16));
  spi_transfer((byte)(address>>8));
  spi_transfer((byte)(address));

  deselect_chip();

  readStatus();
  
  delay(BLOCK_ERASE_TIME);
  
  readStatus();
}

void eraseChip() {
  readStatus();
  enableWrite();
  readStatus();
  
  select_chip();
  spiWrite(CHPE);
  deselect_chip();

  readStatus();
  delay(CHIP_ERASE_TIME);
  readStatus();
}

void enableWrite() {
  select_chip();
  spi_transfer(WREN);
  deselect_chip();
  
  delay(WRITE_STATUS_REGISTER_TIME);
}

void disableWrite() {
  select_chip();
  spi_transfer(WRDI);
  deselect_chip();
  
  delay(WRITE_STATUS_REGISTER_TIME);
}

byte spi_transfer(byte data) {
  spiWrite(data);
  return spiRead();
}

void spiWrite(byte data) {
  SPDR = data;
}

byte spiRead() {
  while (!(SPSR & (1<<SPIF))) {
    // Wait for the end of the transmission
  };
  
  // return the received byte
  return SPDR;
}

void select_chip() {
  digitalWrite(CS, LOW);
  delay(1);
}

void deselect_chip() {
  digitalWrite(CS, HIGH);
  delay(4);
}
