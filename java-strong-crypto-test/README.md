# Test if you have strong crypto support for Java enabled

### OpenJDK not affected
OpenJDK (not to be confused with **Oracle JDK**) supports modern cyphers, so use this if possible and avoid the issue entirely.

### Oracle JDK 8 ships with insecure cyphers
Due to absurd legacy [restrictions on export of cryptography](https://en.wikipedia.org/wiki/Export_of_cryptography_from_the_United_States), the Oracle JDK does not support modern, secure cryptographic cyphers by default.  To make matters worse, Oracle does not support secure download over TLS or supply a checksum, so there is **no way to verify** if the files you download are genuine or fake due to [MITM attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack).

Users of JDK 8 must install 2 jar files like so:

    $ wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip

    # Verify the hash of jce_policy-8.zip == f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59
    # How do we know this is the real checksum?  We don't, but a google search suggests this
    # is the most likely checksum according to several project maintainers.
    $ sha256sum jce_policy-8.zip
    # If the hash matches, then continue, otherwise STOP and figure out why your file is different.

    $ unzip jce_policy-8.zip
    $ sudo cp UnlimitedJCEPolicyJDK8/{US_export_policy.jar,local_policy.jar} $JAVA_HOME/jre/lib/security/
    $ sudo chmod 664 $JAVA_HOME/jre/lib/security/{US_export_policy.jar,local_policy.jar}
    $ sudo rm -rf UnlimitedJCEPolicyJDK8 jce_policy-8.zip

### Oracle [JDK 9 will support strong cyphers](http://stackoverflow.com/a/39872144/1117929), but they must be explicitly enabled

You can enable modern cyphers using:

    import java.security.Security;
    ...
    Security.setProperty("crypto.policy", "unlimited");

### Testing if strong cyphers are available on your system
I created this small class to test for strong crypto:

* [CryptoTest.java](CryptoTest.java)

You can download the java code or class and test like so:

    javac CryptoTest.java
    java -cp . CryptoTest

Success example:

    Testing javax.crypto.Cipher key lengths:
     • Congratulations, you have unlimited key length support!
     • Max key length: 2147483647

Failure example:

    Testing javax.crypto.Cipher key lengths:
     • Warning: strong crypto not enabled.
     • For Java 7 and 8, you can install required jars from here:
       http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip
     • For Java 9, you simply enable it in your app like so:
       Security.setProperty("crypto.policy", "unlimited");
     • Max key length: 128

Or you might see this on damaged / old systems:

    ERROR: Could not determine max key length from Cipher.getMaxAllowedKeyLength("AES")

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
