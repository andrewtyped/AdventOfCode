using System;
using System.Collections.Generic;
using System.IO;
using System.Numerics;
using static day24.Direction;

namespace day24
{
    public enum Direction
    {
        East,
        NorthEast,
        NorthWest,
        SouthEast,
        SouthWest,
        West
    }

    public static class DirectionCoordinateChange
    {
        public static IReadOnlyDictionary<Direction, Vector2> Map = new Dictionary<Direction, Vector2>()
                                                                    {
                                                                        [East] = new Vector2(1, 0),
                                                                        [NorthEast] = new Vector2(1, -1),
                                                                        [NorthWest] = new Vector2(0, -1),
                                                                        [SouthEast] = new Vector2(0, 1),
                                                                        [SouthWest] = new Vector2(-1, 1),
                                                                        [West] = new Vector2(-1, 0)
                                                                    };
    }

    public static class Vector2Extensions
    {
        public static IEnumerable<Vector2> GetAdjacentTiles(this Vector2 vector)
        {
            foreach(var directionalVector in DirectionCoordinateChange.Map.Values)
            {
                yield return vector + directionalVector;
            }
        }
    }

    public class Path
    {
        public readonly List<Direction> Directions = new List<Direction>();

        public void Add(Direction direction) => Directions.Add(direction);

        public Vector2 GetDestination()
        {
            var vector = new Vector2(0,
                                    0);

            foreach(var direction in Directions)
            {
                vector += DirectionCoordinateChange.Map[direction];
            }

            return vector;
        }
    }

    class Program
    {
        private static Dictionary<Direction, Vector2> DirectionCoordinateChangeMap = new Dictionary<Direction, Vector2>()
                                                                                     {
                                                                                         [East] = new Vector2(1, 0),
                                                                                         [NorthEast] = new Vector2(1, -1),
                                                                                         [NorthWest] = new Vector2(0, -1),
                                                                                         [SouthEast] = new Vector2(0, 1),
                                                                                         [SouthWest] = new Vector2(-1, 1),
                                                                                         [West] = new Vector2(-1, 0)
                                                                                     };

        static void Main(string[] args)
        {
            if (args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day24.exe "".\path\to\input.txt""");
            }

            using var sr = new StreamReader(args[0]);

            var paths = new List<Path>();
            var blackTiles = new HashSet<Vector2>();

            while (!sr.EndOfStream)
            {
                var line = sr.ReadLine();

                var path = ParsePath(line);
                paths.Add(path);
            }

            foreach(var path in paths)
            {
                var destination = path.GetDestination();

                if (!blackTiles.Add(destination))
                {
                    blackTiles.Remove(destination);
                }
            }

            Console.WriteLine($"Black Tiles: {blackTiles.Count}");

            //Phase 2

            for(int i = 0; i < 100; i++)
            {
                var tileAdjacentBlackTilesMap = new Dictionary<Vector2, int>();
                var newWhiteTiles = new HashSet<Vector2>();
                var newBlackTiles = new HashSet<Vector2>();

                foreach(var blackTile in blackTiles)
                {
                    tileAdjacentBlackTilesMap.TryAdd(blackTile,
                                                     0);

                    foreach( var adjacentTile in blackTile.GetAdjacentTiles())
                    {
                        if (tileAdjacentBlackTilesMap.TryGetValue(adjacentTile,
                                                           out var adjacentBlackTileCount))
                        {
                            tileAdjacentBlackTilesMap[adjacentTile] = ++adjacentBlackTileCount;
                        }
                        else
                        {
                            tileAdjacentBlackTilesMap[adjacentTile] = 1;
                        }
                    }
                }

                foreach(var tileAdjacentBlackTilesKvp in tileAdjacentBlackTilesMap)
                {
                    var tile = tileAdjacentBlackTilesKvp.Key;
                    var adjacentBlackTiles = tileAdjacentBlackTilesKvp.Value;

                    if (blackTiles.Contains(tile))
                    {
                        if(adjacentBlackTiles == 0 || adjacentBlackTiles > 2)
                        {
                            blackTiles.Remove(tile);
                        }
                    }
                    else if (adjacentBlackTiles == 2)
                    {
                        blackTiles.Add(tile);
                    }
                }

                Console.WriteLine($"Black tiles after {i + 1} days: {blackTiles.Count}");
            }
        }

        static Path ParsePath(string rawPath)
        {
            var path = new Path();

            for(int i = 0; i < rawPath.Length; i++)
            {
                char current = rawPath[i];

                Direction direction = current switch
                {
                    'e' => East,
                    'w' => West,
                    's' when rawPath[i + 1] == 'e' => SouthEast,
                    's' when rawPath[i + 1] == 'w' => SouthWest,
                    'n' when rawPath[i + 1] == 'e' => NorthEast,
                    'n' when rawPath[i + 1] == 'w' => NorthWest,
                    _ => throw new FormatException($"Illegal character {current}")
                };

                path.Add(direction);

                if(direction != East && direction != West)
                {
                    i++;
                }
            }

            return path;
        }
    }
}
