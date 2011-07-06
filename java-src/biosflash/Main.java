package biosflash;

import gnu.io.CommPort;
import gnu.io.CommPortIdentifier;
import gnu.io.NoSuchPortException;
import gnu.io.PortInUseException;
import gnu.io.SerialPort;
import gnu.io.UnsupportedCommOperationException;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;

/**
 * @author Michael Kanis
 */
class Main extends Thread {

	private Programmer programmer;

	private final File file;

	private Main(File file) {

		this.file = file;

		try {
			connect("/dev/ttyS4");
		} catch (NoSuchPortException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (PortInUseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (UnsupportedCommOperationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

	private void connect(String portName) throws NoSuchPortException,
			PortInUseException, UnsupportedCommOperationException, IOException {

		CommPortIdentifier portIdentifier = CommPortIdentifier
				.getPortIdentifier(portName);

		CommPort port = portIdentifier.open(this.getClass().getName(), 2000);

		if (port instanceof SerialPort) {
			SerialPort serialPort = (SerialPort) port;
			serialPort.setSerialPortParams(115200, SerialPort.DATABITS_8,
					SerialPort.STOPBITS_1, SerialPort.PARITY_NONE);

			// inputStream = serialPort.getInputStream();
			OutputStream out = serialPort.getOutputStream();

			programmer = new Programmer(out, new FileInputStream(file));
			programmer.start();

		} else {
			throw new IllegalArgumentException(
					"Only serial ports are handled by this program.");
		}
	}

	public static void main(String[] args) {

		Main main = new Main(new File(args[0]));

	}

}
