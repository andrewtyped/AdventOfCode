using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using System.Numerics;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;

namespace day17
{
    class Program
    {
        private const int maxNeighbors = 3;

        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day17.exe "".\path\to\input.txt""");
            }

            using var sr = new StreamReader(args[0]);

            var activeCubes = new HashSet<Vector4>();
            const int cycleCount = 6;

            int rows = 0;
            int columns = 0;

            var initialInput = new StringBuilder();
            var initialLayer = 0;
            var initialHyperLayer = 0;
            while (!sr.EndOfStream)
            {
                var line = sr.ReadLine();
                columns = line.Length;
                initialInput.Append(line);

                for(int i = 0; i < line.Length; i++)
                {
                    if (line[i] == '#')
                    {
                        activeCubes.Add(new Vector4(i,
                                                    rows,
                                                    initialLayer,
                                                    initialHyperLayer));
                    }
                }

                rows++;
            }

            var mutex = new object();

            for(int cycle = 0; cycle < cycleCount; cycle++)
            {
                var nextCubeStates = new ConcurrentDictionary<Vector4, int>();
                var nextActiveCubes = new HashSet<Vector4>();

                Parallel.ForEach(activeCubes,
                                 activeCube =>
                                 {
                                     foreach (var adjacentCube in GetAdjacentVectors(activeCube).ToArray())
                                     {
                                         nextCubeStates.AddOrUpdate(adjacentCube,
                                                                    1,
                                                                    (existingAdjacentCube,
                                                                     activeNeighbors) => activeNeighbors + 1);
                                     }
                                 });

                Parallel.ForEach(nextCubeStates,
                                 nextCubeState =>
                                 {
                                     if (nextCubeState.Value == 3)
                                     {
                                         lock (mutex)
                                         {
                                             nextActiveCubes.Add(nextCubeState.Key);
                                         }
                                     }
                                     else if (nextCubeState.Value == 2
                                              && activeCubes.Contains(nextCubeState.Key))
                                     {
                                         lock (mutex)
                                         {
                                             nextActiveCubes.Add(nextCubeState.Key);
                                         }
                                     }
                                 });

                activeCubes = nextActiveCubes;
            }

            Console.WriteLine($"Active Cubes: {activeCubes.Count}");
        }

        static IEnumerable<Vector4> GetAdjacentVectors(Vector4 vector)
        {
            for(int x = -1; x <= 1; x++)
            {
                var newX = vector.X + x;

                for(int y = -1; y <= 1; y++)
                {
                    var newY = vector.Y + y;

                    for(int z = -1; z <= 1; z++)
                    {
                        var newZ = vector.Z + z;

                        for (int w = -1;
                             w <= 1;
                             w++)
                        {
                            var newW = vector.W + w;
                            var adjacentVector = new Vector4(newX,
                                                             newY,
                                                             newZ,
                                                             newW);
                            if (vector != adjacentVector)
                            {
                                yield return adjacentVector;
                            }
                        }
                    }
                }
            }
        }
    }
}
