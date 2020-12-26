using System;
using System.IO;

namespace day25
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day25.exe "".\path\to\input.txt""");
                return;
            }

            using var sr = new StreamReader(args[0]);

            int cardPublicKey = int.Parse(sr.ReadLine());
            int doorPublicKey = int.Parse(sr.ReadLine());

            int cardSecretLoopSize = GetSecretLoopSize(cardPublicKey);
            int doorSecretLoopSize = GetSecretLoopSize(doorPublicKey);

            Console.WriteLine($"Card secret loop size: {cardSecretLoopSize}");
            Console.WriteLine($"Door secret loop size: {doorSecretLoopSize}");

            long doorEncryptionKey = Transform(cardPublicKey,
                                              doorSecretLoopSize);
            long cardEncryptionKey = Transform(cardPublicKey,
                                          doorSecretLoopSize);
            Console.WriteLine($"Card Encryption Key: {cardEncryptionKey}");
            Console.WriteLine($"Door Encryption Key: {doorEncryptionKey}");
        }

        static int GetSecretLoopSize(int publicKey)
        {
            int subject = 7;
            int divisor = 20201227;
            long currentValue = 1;
            int secretLoopSize = 0;

            while (currentValue != publicKey)
            {
                currentValue = currentValue * subject;
                currentValue = currentValue % divisor;
                secretLoopSize++;
            }

            return secretLoopSize;
        }

        static long Transform(int subject, int loopSize)
        {
            int divisor = 20201227;
            long currentValue = 1;

            for(int i = 0; i < loopSize; i++)
            {
                currentValue = currentValue * subject;
                currentValue = currentValue % divisor;
            }

            return currentValue;
        }
    }
}
