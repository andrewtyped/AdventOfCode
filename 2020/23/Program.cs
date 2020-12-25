using System;
using System.Collections.Generic;
using System.Linq;

namespace day23
{
    class Program
    {
        private const int Rounds = 10000000;

        private const int AdditionalCups = 1000000;

        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day23.exe ""123456789""");
                return;
            }

            string input = args[0];
            int[] cups = ParseInput(input);

            PlayGame(cups,
                     Rounds);
        }

        static int[] ParseInput(string input)
        {
            int[] numbers = new int[input.Length];

            for(int i = 0; i < input.Length; i++)
            {
                numbers[i] = (int)char.GetNumericValue(input[i]);
            }

            return numbers;
        }

        static void PlayGame(int[] cups,
                             int rounds)
        {
            
            var minCup = cups.Min();
            var initialMaxCup = cups.Max();
            var maxCup = AdditionalCups;
            var cupsLinked = new LinkedList<int>(cups);
            var cupsDict = new Dictionary<int, LinkedListNode<int>>();
            var currentCup = cupsLinked.First;

            foreach(var cup in cupsLinked)
            {
                cupsDict[cup] = cupsLinked.Find(cup);
            }

            for(int i = initialMaxCup + 1; i <= AdditionalCups; i++)
            {
                var node = cupsLinked.AddLast(i);
                cupsDict[i] = node;
            }

            for (int round = 0;
                 round < rounds;
                 round++)
            {
                //Pick up cups

                if(round % 1000 == 0)
                {
                    Console.WriteLine($"Current round is {round}");
                }

                var pickedUpCups = new List<int>();
                for (int i = 0;
                     i < 3;
                     i++)
                {
                    var nextCup = currentCup.Next;

                    if (nextCup == null)
                    {
                        nextCup = cupsLinked.First;
                    }

                    pickedUpCups.Add(nextCup.Value);
                    cupsLinked.Remove(nextCup);
                }

                //Select destination cup
                int destinationCupValue = currentCup.Value - 1;
                LinkedListNode<int> destinationCup = null;

                while (destinationCup == null)
                {
                    if (pickedUpCups.Contains(destinationCupValue)
                        || !cupsDict.TryGetValue(destinationCupValue,
                                                 out destinationCup))
                    {
                        destinationCupValue--;

                        if (destinationCupValue < minCup)
                        {
                            destinationCupValue = maxCup;
                        }
                    }
                }
            

                //Insert cups
                for(int i = pickedUpCups.Count - 1; i >= 0; i--)
                {
                    var insertedNode = cupsLinked.AddAfter(destinationCup,
                                                           pickedUpCups[i]);
                    cupsDict[pickedUpCups[i]] = insertedNode;
                }

                //Select new current cup
                currentCup = currentCup.Next;
                
                if(currentCup == null)
                {
                    currentCup = cupsLinked.First;
                }
            }

            foreach(var cup in cupsLinked)
            {
                Console.Write(cup);
            }

            Console.WriteLine();

            currentCup = cupsLinked.Find(1);

            while(currentCup.Next != null)
            {
                Console.Write(currentCup.Next.Value);
                Console.Write(" ");
                currentCup = currentCup.Next;
            }

            currentCup = cupsLinked.First;

            while(currentCup.Value != 1)
            {
                Console.Write(currentCup.Value);
                Console.Write(" ");
                currentCup = currentCup.Next;
            }
        }
    }
}
