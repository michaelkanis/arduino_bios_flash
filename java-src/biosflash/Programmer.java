package biosflash;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/** */
class Programmer extends Thread {

	// /** The opcode for the chip erase command. */
	// private static byte OPCODE_CHIP_ERASE = (byte) 0xC7;

	/** The opcode for the page program command. */
	private static byte OPCODE_PAGE_PROGRAM = 0x02;

	/** Each page on the chip is 256 bytes. */
	private static int PAGE_SIZE = 256;

	private final OutputStream out;

	private final InputStream source;

	private int address = 0;

	public Programmer(OutputStream out, InputStream source) {
		this.out = out;
		this.source = source;
	}

	@Override
	public void run() {
		try {
			int bytesRead = 0;
			final byte[] buffer = new byte[PAGE_SIZE];

			// read PAGE_SIZE bytes from input stream and program it to the chip
			while ((bytesRead = source.read(buffer)) > -1) {

				// the bios file is definitely a factor of PAGE_SIZE
				if (bytesRead != PAGE_SIZE) {
					throw new IllegalStateException();
				}

				programPage(buffer);

				waitTillReady();

			}
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private synchronized void waitTillReady() {
		try {
			Thread.sleep(250);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private void programPage(final byte[] data) throws IOException {

		// send page program opcode to Arduino
		out.write(OPCODE_PAGE_PROGRAM);

		// send address to Arduino, MSB first
		out.write((address >> 16));
		out.write((address >> 8));
		out.write(address);

		// send data to Arduino
		out.write(data);

		address = address + PAGE_SIZE;

	}

}