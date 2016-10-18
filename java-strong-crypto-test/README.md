# Simple test to see if you have strong crypto support for Java enabled.

### JDK 8 ships with insecure cyphers
Due to absurd legacy [restrictions on export of cryptography](https://en.wikipedia.org/wiki/Export_of_cryptography_from_the_United_States), the Oracle JDK does not support secure cryptography cyphers by default.

Instead, users of JDK 8 must install 2 jars like so:

    $ wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip

    # Verify the hash of jce_policy-8.zip == f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59
    $ sha256sum jce_policy-8.zip
    # If the hash matches, then continue, otherwise STOP and figure out why your file is different.

    $ unzip jce_policy-8.zip
    $ sudo cp UnlimitedJCEPolicyJDK8/US_export_policy.jar $JAVA_HOME/jre/lib/security/
    $ sudo cp UnlimitedJCEPolicyJDK8/local_policy.jar $JAVA_HOME/jre/lib/security/
    $ sudo chmod 777 $JAVA_HOME/jre/lib/security/US_export_policy.jar
    $ sudo chmod 777 $JAVA_HOME/jre/lib/security/local_policy.jar
    $ sudo rm -rf UnlimitedJCEPolicyJDK8 jce_policy-8.zip

### JDK 9 Will [aparently support strong cyphers](http://stackoverflow.com/a/39872144/1117929), but they must be explicitly enabled.

You can enable modern cyphers using:

    import java.security.Security;
    ...
    Security.setProperty("crypto.policy", "unlimited");

### Testing if strong cyphers are supported on your system
I created this small class to test for strong crypto:

* [CryptoTest.java](CryptoTest.java)

You can download and test liks so:

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

### License

    The MIT License (MIT)

    Copyright (c) 2009-2016 The Bitcoin Core developers

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
