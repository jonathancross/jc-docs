# Diceware Entropy Improvement

As you may know, you can use dice to generate true random numbers.  These random numbers can be very helpful for generating secure passphrases, Bitcoin private keys, etc (via [Diceware](https://en.wikipedia.org/wiki/Diceware)) as the real-world entropy source is more "random" than computer-generated randomness.  Dice are much harder to backdoor / switch on you than a piece of computer software / hardware -- especially if you use [professional weighted casino dice](https://vitalvegas.com/casino-dice-security-measures-cheating/).

But maybe we can take it a step further?

How might one add further randomness to the Diceware results without typing the Diceware results into a computer?

It turns out that one can always add entropy sources together without risk of reducing entropy.  We can therefore add computer-generated entropy to our offline-dice entropy -- [Belt and Suspenders](https://en.wiktionary.org/wiki/belt_and_suspenders) so to speak.

How it's done
-------------

First generate your Diceware numbers by rolling dice (range 1-6) eg:

    4 6 2 3 4 1 ...

Then subtract 1 from each of the numbers to create a range of 0-5:

    3 5 1 2 3 0 ...

## Second source of entropy

Your second source of entropy should also give you a set of numbers, each being between 0 and 5 with equal probability.

Example in python3:

```python
import random
rand = random.SystemRandom()
for x in range(128):
  print(str(rand.randint(0,5)), end=' ')
```

Result:

    5 4 0 5 2 3 ...

## Adding the entropy with mod

So now you have two sets of numbers, your original roll and an independent numbers generated with Python, etc.  You want to combine these such that you benefit from the entropy of both sources without reducing entropy from a potentially bad source (incorrectly weighted dice for example).  To do this, simply add the numbers together, if the result is larger than or equal to 6, subtract 6. This is called a [modulo operation](https://en.wikipedia.org/wiki/Modulo_operation), e.g. (2 mod 6) is 2, but (7 mod 6) is 1, or (6 mod 6) is 0.

#### Some examples:

    a=2
    b=3
    result: 5

or

    a=3
    b=3
    result: (3+3=6) mod 6 = 0 

or

    a=5
    b=4
    result: (5+4=9) mod 6 = 3

or

    a=5
    b=5
    result: 10 mod 6 == 4

The results of our example in the previous section:

     DICE:   3 5 1 2 3 0 ...
     PYTHON: 5 4 0 5 2 3 ...
     RESULT: 2 3 1 1 5 3 ...

Once you have done this for every number, go through the new list and **add 1** to each number to get back to a range of 1-6.

Final numbers from example above (with 1 added):

     RESULT: 3 4 2 2 6 4 ...

## Notes

All of these calculations are trivial to do offline with a piece of paper and pencil.  This avoids a wide range of computer-based malware attacks that could manipulate your numbers, steal your final Diceware passphrase, etc.

This method can also be used to generate extremely high quality entropy for Bitcoin keys, PGP keys, etc.  Those use cases require additional work to transform the entropy into a private / public key-pair which is outside the scope of this document.

#### More about how it works

As long as your secondary source does not correlate with your dice, the second source can even be non-random or non-uniform and it won't decrease your entropy (that can only happen if the 2nd source is influenced by the first, which includes your own brain!)

An example of your brain reducing entropy: if you try to "guess a number" after you've seen the result of the first roll.

The nice thing about this method is that if *either* of the sources is a uniform (unbiased), then the combination of both also is unbiased. So if your weighted dice had a backdoor, but your 2<sup>nd</sup> source did not, you are safe, and vice versa.  You can even add in a third source if you want.

Here is a [proof of the math](https://math.stackexchange.com/a/2966543) involved.

### Acknowledgments

Thanks to Marko Bencun [@benma](https://github.com/benma) (of [Shift Cryptosecurity](https://shiftcrypto.ch/)) for walking me through this.

### Disclaimer

This document comes with no guarantees, do your own homework. [Feedback](https://github.com/jonathancross/jc-docs/issues/new?title=Feedback:%20Diceware%20Entropy) is welcome.

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.

