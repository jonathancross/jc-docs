import javax.crypto.Cipher;

public class CryptoTest {
  public static void main (String[] arg) {
    try {
      System.out.println("Testing javax.crypto.Cipher key lengths:");
      int maxKeyLen = Cipher.getMaxAllowedKeyLength("AES");
      if (maxKeyLen > 128) {
        System.out.println(" • Congratulations, you have unlimited key length support!");
      } else {
        System.out.println(" • Warning: strong crypto not enabled.");
        System.out.println(" • For Java 7 and 8, you can install required jars from here:");
        System.out.println("   http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip");
        System.out.println(" • For Java 9, you simply enable it in your app like so:");
        System.out.println("   Security.setProperty(\"crypto.policy\", \"unlimited\");");
      }
      System.out.println(" • Max key length: " + maxKeyLen);
    } catch (Exception e){
      System.out.println("ERROR: Could not determin max key length.");
    }
  }
}
