import net.spy.memcached.ArcusClient;
import net.spy.memcached.ConnectionFactoryBuilder;

import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;
import java.util.Scanner;

public class CheckKeyNode extends Thread {
	private Properties prop = new Properties();
	
	private final static String DEFAULT_ARCUS_ADMIN = "127.0.0.1:2181";
	private final static String DEFAULT_ARCUS_SERVICE_CODE = "test";
	
	private ArcusClient client;
	
	public static void main(String[] args) {
		CheckKeyNode key = new CheckKeyNode();
		key.start();
		
		try {
			key.join();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		
		key.close();
	}
	
	public CheckKeyNode() {
		String hostPorts;
		String serviceCode;
		
		try {
			prop.load(new BufferedInputStream(new FileInputStream("app.properties")));
			hostPorts = prop.getProperty("ArcusAdmin");
			serviceCode = prop.getProperty("ArcusServiceCode");
		} catch (FileNotFoundException e) {
			throw new RuntimeException("Application properties file don't exist.", e);
		} catch (IOException e) {
			throw new RuntimeException("Application properties file can't read.", e);
		}
		
		if (hostPorts == null || hostPorts.length() <= 0)
			hostPorts = DEFAULT_ARCUS_ADMIN;
		if (serviceCode == null || serviceCode.length() <= 0)
			serviceCode = DEFAULT_ARCUS_SERVICE_CODE;
		
		System.setProperty("net.spy.log.LoggerImpl", "net.spy.memcached.compat.log.Log4JLogger");
		client = ArcusClient.createArcusClient(hostPorts, serviceCode, new ConnectionFactoryBuilder());
	}
	
	public void run() {
		System.out.println("Find node for key string! Ctrl-D (i.e. EOF) to exit!");
		
		Scanner scanner = new Scanner(System.in);
		String key;
		while (true) {
			System.out.print(">>> ");
			key = scanner.nextLine();
			key = key.trim();
			if (validateKey(key)) {
				String node = new String(client.getNodeLocator().getPrimary(key).getSocketAddress().toString());
				System.out.println("key : " + key + " - node : " + node.substring(node.indexOf('/') + 1));
			} else {
				System.out.println("[INVALIDATE KEY : \"" + key + "\"]");
			}
		}
	}
	
	public boolean validateKey(String key) {
		if (key.length() > 250 || key.length() <= 0) {
			System.out.printf("Invalid key length (%d). ", key.length());
			return false;
		}
		
		if (key.contains("\t") || key.contains(" ")) {
			System.out.print("Can't contain white spaces. ");
			return false;
		}
		
		return true;
	}
	
	public void close() {
		client.shutdown();
	}
}
