using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace day22
{
    class DeckEqualityComparer : IEqualityComparer<IStructuralEquatable>
    {
        public bool Equals([AllowNull] IStructuralEquatable x,
                           [AllowNull] IStructuralEquatable y)
        {
            return x.Equals(y,
                            EqualityComparer<int>.Default);
        }

        public int GetHashCode([DisallowNull] IStructuralEquatable obj)
        {
            return obj.GetHashCode(EqualityComparer<int>.Default);
        }
    }

    class Program
    {
        private const int Player1 = 1;

        private const int Player2 = 2;

        private static int game = 1;

        private static DeckEqualityComparer deckEqualityComparer = new DeckEqualityComparer();

        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day22.exe "".\path\to\input.txt""");
            }

            using var sr = new StreamReader(args[0]);

            var player1Deck = new Queue<int>();
            var player2Deck = new Queue<int>();
            var currentDeck = player1Deck;

            while (!sr.EndOfStream)
            {
                var line = sr.ReadLine();

                if(line.Contains("Player 2"))
                {
                    currentDeck = player2Deck;
                    continue;
                }

                if (int.TryParse(line,
                                 out var card))
                {
                    currentDeck.Enqueue(card);
                }
            }

            var p1DeckPhase2 = CopyDeckSlice(player1Deck,
                                             player1Deck.Count);
            var p2DeckPhase2 = CopyDeckSlice(player2Deck,
                                             player2Deck.Count);

            //var rounds = PlayCombat(player1Deck,
            //                        player2Deck);

            //Console.WriteLine($"Rounds played: {rounds}");

            var p1Score = ScoreDeck(player1Deck);
            var p2Score = ScoreDeck(player2Deck);

            Console.WriteLine($"Player 1 Score: {p1Score}");
            Console.WriteLine($"Player 2 Score: {p2Score}");

            PlayRecursiveCombat(p1DeckPhase2,
                                p2DeckPhase2);

            p1Score = ScoreDeck(p1DeckPhase2);
            p2Score = ScoreDeck(p2DeckPhase2);

            Console.WriteLine($"Player 1 Recursive Combat Score: {p1Score}");
            Console.WriteLine($"Player 2 Recursive Combat Score: {p2Score}");
        }

        static int PlayCombat(Queue<int> p1Deck, Queue<int> p2Deck)
        {
            int rounds = 0;

            while(p1Deck.Count > 0 && p2Deck.Count > 0)
            {
                PlayCombatRound(p1Deck,
                                p2Deck);

                rounds++;
            }

            return rounds;
        }

        static void PlayCombatRound(Queue<int> p1Deck, Queue<int> p2Deck)
        {
            var p1Card = p1Deck.Dequeue();
            var p2Card = p2Deck.Dequeue();

            var winner = Math.Max(p1Card,
                                  p2Card);

            if(winner == p1Card)
            {
                p1Deck.Enqueue(p1Card);
                p1Deck.Enqueue(p2Card);
            }
            else
            {
                p2Deck.Enqueue(p2Card);
                p2Deck.Enqueue(p1Card);
            }
        }

        static int PlayRecursiveCombat(Queue<int> p1Deck, Queue<int> p2Deck)
        {
            int rounds = 0;

            var p1PreviousHands = new HashSet<IStructuralEquatable>(deckEqualityComparer);
            var p2PreviousHands = new HashSet<IStructuralEquatable>(deckEqualityComparer);

            #if DEBUG
                Console.WriteLine($"=== Game {game} ===");
                Console.WriteLine();
            #endif

            while(p1Deck.Count > 0 && p2Deck.Count > 0)
            {
                rounds++;

                #if DEBUG
                    Console.WriteLine($"-- Round {rounds} (Game {game}) --");
                    PrintDeck(Player1,p1Deck);
                    PrintDeck(Player2,p2Deck);
                #endif

                if(!p1PreviousHands.Add(p1Deck.ToArray()) || !p2PreviousHands.Add(p2Deck.ToArray()))
                {
                    return Player1;
                }

                var roundWinnder = PlayRecursiveCombatRound(p1Deck,
                                                            p2Deck);

                #if DEBUG
                    Console.WriteLine($"Player {roundWinnder} wins round {rounds} of game {game}!");
                    Console.WriteLine();
                #endif
            }

            var gameWinner = p1Deck.Count > 0
                                 ? Player1
                                 : Player2;

            #if DEBUG
                Console.WriteLine($"Player {gameWinner} wins game {game}!");
                Console.WriteLine();
            #endif

            return gameWinner;
        }

        static int PlayRecursiveCombatRound(Queue<int> p1Deck, Queue<int> p2Deck)
        {
            var p1Card = p1Deck.Dequeue();
            var p2Card = p2Deck.Dequeue();

            #if DEBUG
                Console.WriteLine($"Player 1 plays {p1Card}");
                Console.WriteLine($"Player 2 plays {p2Card}");
            #endif

            int winner;

            if (p1Deck.Count >= p1Card
                && p2Deck.Count >= p2Card)
            {
                var p1SlicedDeck = CopyDeckSlice(p1Deck,
                                                 p1Card);
                var p2SlicedDeck = CopyDeckSlice(p2Deck,
                                                 p2Card);
                game++;
                winner = PlayRecursiveCombat(p1SlicedDeck,
                                             p2SlicedDeck);
            }
            else
            {
                var maxCard = Math.Max(p1Card,
                                       p2Card);

                winner = maxCard == p1Card
                             ? Player1
                             : Player2;
            }

            if(winner == Player1)
            {
                p1Deck.Enqueue(p1Card);
                p1Deck.Enqueue(p2Card);
            }
            else
            {
                p2Deck.Enqueue(p2Card);
                p2Deck.Enqueue(p1Card);
            }

            return winner;
        }

        static Queue<int> CopyDeckSlice(Queue<int> deck, int sliceSize)
        {
            var slicedDeck = new Queue<int>();

            foreach(var card in deck.Take(sliceSize))
            {
                slicedDeck.Enqueue(card);
            }

            return slicedDeck;
        }

        static int ScoreDeck(Queue<int> deck)
        {
            int counter = deck.Count;
            int score = 0;

            while(deck.TryDequeue(out var card))
            {
                score += counter * card;
                counter--;
            }

            return score;
        }

        static void PrintDeck(int player, Queue<int> deck)
        {
            var sb = new StringBuilder();
            sb.Append($"Player {player} deck: ");

            foreach(var card in deck)
            {
                sb.Append(card + ", ");
            }

            Console.WriteLine(sb.ToString());
        }
    }
}
