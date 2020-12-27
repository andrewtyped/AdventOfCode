using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Numerics;

namespace day20
{
    public static class EdgeIdTileMapExtensions
    {
        public static bool ContainsPairedEdge(this Dictionary<(Edge Edge, int Id), List<Tile>> edgeIdTileMap, int tileId, Edge edge, int id)
        {
            if(edgeIdTileMap.TryGetValue((edge, id), out var matchedTiles))
            {
                return matchedTiles.Any(tile => tile.Id != tileId);
            }
            else
            {
                return false;
            }
        }

        public static bool TryGetEdges(this Dictionary<(Edge Edge, int Id), List<Tile>> edgeIdTileMap,
                                       int tileId,
                                       Edge edge,
                                       int id,
                                       out List<Tile> matchedTiles)
        {
            if (edgeIdTileMap.TryGetValue((edge, id),
                                          out var possibleMatchedTiles))
            {
                matchedTiles = possibleMatchedTiles.Where(tile => tile.Id != tileId)
                                                   .ToList();
                return true;
            }
            else
            {
                matchedTiles = new List<Tile>();
                return false;
            }
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day20.exe "".\path\to\input.txt""");
            }

            var tiles = ParseTiles(args[0]);

            Console.WriteLine($"Tiles: {tiles.Count}");

            var tileRotations = GetTileRotations(tiles);
            var image = InitializeImage(tiles);
            var edgeIdTileMap = GetEdgeIdTileMap(tileRotations);
            var possibleCornerTiles = GetPossibleCornerTiles(tileRotations,
                                                             edgeIdTileMap);

            var cornerTileIdsProduct = possibleCornerTiles.Select(tile => (long)tile.Id)
                                                          .Distinct()
                                                          .Aggregate((acc,
                                                                      curr) => acc * curr);
            Console.WriteLine($"Corner tile Ids product: {cornerTileIdsProduct}");

            AssembleImage(image,
                          possibleCornerTiles,
                          tileRotations,
                          edgeIdTileMap);
            TrimImageBorders(image);

            var resolvedImage = ResolveImage(image: image);
            var seaMonsters = CountSeaMonsters(resolvedImage);

            Console.WriteLine($"Sea monsters found: {seaMonsters}");

            var waterRoughness = CalculateWaterRoughness(resolvedImage,
                                                         seaMonsters);

            Console.WriteLine($"Water Roughness: {waterRoughness}");
        }

        private static int CalculateWaterRoughness(Tile resolvedImage, 
                                                   in int seaMonsters)
        {
            int waterTilesPerSeaMonster = 15;
            int seaMonsterPoints = seaMonsters * waterTilesPerSeaMonster;
            int waterTiles = 0;

            for(int i = 0; i < resolvedImage.Rows.Length; i++)
            {
                for(int j = 0; j < resolvedImage.Columns.Length; j++)
                {
                    if (resolvedImage.Rows[i][j])
                    {
                        waterTiles++;
                    }
                }
            }

            return waterTiles - seaMonsterPoints;
        }

        private static int CountSeaMonsters(Tile image)
        {
            var seaMonsterLength = 20;
            var checks = new Vector2[]
                         {
                             new Vector2(1,
                                         1),
                             new Vector2(4,
                                         1),
                             new Vector2(5,
                                         0),
                             new Vector2(6,
                                         0),
                             new Vector2(7,
                                         1),
                             new Vector2(10,
                                         1),
                             new Vector2(11,
                                         0),
                             new Vector2(12,
                                         0),
                             new Vector2(13,
                                         1),
                             new Vector2(16,
                                         1),
                             new Vector2(17,
                                         0),
                             new Vector2(18,
                                         0),
                             new Vector2(18,
                                         -1),
                             new Vector2(19,
                                         0)
                         };

            var seaMonstersFound = 0;

            foreach(var rotatedImage in image.GetAllTileOrientations())
            {
                for (int row = 1;
                     row < rotatedImage.Rows.Length - 1;
                     row++)
                {
                    for (int column = 0;
                         column < rotatedImage.Columns.Length - seaMonsterLength;
                         column++)
                    {
                        var current = rotatedImage.Rows[row][column];

                        if (current)
                        {
                            var seaMonsterFound = true;

                            foreach(var check in checks)
                            {
                                var rowToCheck = row + (int)check.Y;
                                var columnToCheck = column + (int)check.X;

                                if (!rotatedImage.Rows[rowToCheck][columnToCheck])
                                {
                                    seaMonsterFound = false;
                                    break;
                                }
                            }

                            if (seaMonsterFound)
                            {
                                seaMonstersFound++;
                            }
                        }
                    }
                }

                if(seaMonstersFound > 0)
                {
                    break;
                }
            }

            return seaMonstersFound;
        }

        private static void TrimImageBorders(Tile[][] image)
        {
            for(int i = 0; i < image.Length; i++)
            {
                for(int j = 0; j < image[0].Length; j++)
                {
                    image[i][j] = image[i][j]
                        .TrimBorder();
                }
            }
        }

        private static Tile ResolveImage(Tile[][] image)
        {
            int rowsPerImageTile = image[0][0]
                                   .Rows.Length;
            int columnsPerImageTile = image[0][0]
                                      .Columns.Length;
            var finalImageHeight = image.Length
                                   * rowsPerImageTile;
            var finalImageWidth = image[0]
                                      .Length
                                  * columnsPerImageTile;

            var finalImageRows = new bool[finalImageHeight][];


            for (int row = 0;
                 row < finalImageHeight;
                 row++)
            {
                var imageTileRow = row / rowsPerImageTile;
                var finalImageRow = new bool[finalImageWidth];
                finalImageRows[row] = finalImageRow;
                for (int column = 0;
                     column < finalImageWidth;
                     column++)
                {
                    var imageTileColumn = column / columnsPerImageTile;
                    var imageTile = image[imageTileRow][imageTileColumn];
                    var tileColumn = column % columnsPerImageTile;
                    var tileRow = row % rowsPerImageTile;
                    finalImageRow[column] = imageTile.Rows[tileRow][tileColumn];
                }
            }

            var renderedTile = new Tile(0,
                                        finalImageRows);

            return renderedTile;
        }

        private static void AssembleImage(Tile[][] image,
                                          IEnumerable<Tile> possibleCornerTiles,
                                          Dictionary<int, List<Tile>> tileRotations,
                                          Dictionary<(Edge Edge, int Id), List<Tile>> edgeIdTileMap)
        {
            var placedTiles = new HashSet<int>();
            bool validImage = true;

            foreach(var possibleCornerTile in possibleCornerTiles)
            {
                placedTiles.Clear();
                for(int row = 0; row < image.Length; row++)
                {
                    var currentRow = image[row];

                    for(int column = 0; column < currentRow.Length; column++)
                    {
                        if(row == 0 && column == 0)
                        {
                            image[row][column] = possibleCornerTile;
                            placedTiles.Add(possibleCornerTile.Id);
                            continue;
                        }

                        if(row == 0)
                        {
                            var leftwardTile = image[row][column - 1];

                            if (edgeIdTileMap.TryGetEdges(leftwardTile.Id,
                                                          Edge.Left,
                                                          leftwardTile.EdgeIds[Edge.Right],
                                                          out var matches))
                            {
                                foreach(var match in matches)
                                {
                                    if (placedTiles.Contains(match.Id))
                                    {
                                        continue;
                                    }

                                    if (edgeIdTileMap.ContainsPairedEdge(match.Id,
                                                                         Edge.Bottom,
                                                                         match.EdgeIds[Edge.Top]))
                                    {
                                        continue;
                                    }

                                    image[row][column] = match;
                                    placedTiles.Add(match.Id);
                                    break;
                                }
                            }
                        }

                        if(column == 0)
                        {
                            var upwardTile = image[row - 1][column];

                            if (edgeIdTileMap.TryGetEdges(upwardTile.Id,
                                                          Edge.Top,
                                                          upwardTile.EdgeIds[Edge.Bottom],
                                                          out var matches))
                            {
                                foreach(var match in matches)
                                {
                                    if (placedTiles.Contains(match.Id))
                                    {
                                        continue;
                                    }

                                    if (edgeIdTileMap.ContainsPairedEdge(match.Id,
                                                                         Edge.Right,
                                                                         match.EdgeIds[Edge.Left]))
                                    {
                                        continue;
                                    }

                                    image[row][column] = match;
                                    placedTiles.Add(match.Id);
                                    break;
                                }
                            }
                        }

                        if(row != 0 && column != 0)
                        {
                            var leftwardTile = image[row][column - 1];
                            var upwardTile = image[row - 1][column];

                            if (edgeIdTileMap.TryGetEdges(leftwardTile.Id,
                                                          Edge.Left,
                                                          leftwardTile.EdgeIds[Edge.Right],
                                                          out var matches))
                            {
                                foreach (var match in matches)
                                {
                                    if (placedTiles.Contains(match.Id))
                                    {
                                        continue;
                                    }

                                    if(upwardTile.EdgeIds[Edge.Bottom] != match.EdgeIds[Edge.Top])
                                    {
                                        continue;
                                    }

                                    image[row][column] = match;
                                    placedTiles.Add(match.Id);
                                    break;
                                }
                            }
                        }

                        if(image[row][column] == null)
                        {
                            validImage = false;
                            break;
                        }
                    }

                    if (!validImage)
                    {
                        break;
                    }
                }

                if (validImage)
                {
                    break;
                }
                else
                {
                    validImage = true;
                }
            }
        }

        private static IEnumerable<Tile> GetPossibleCornerTiles(Dictionary<int, List<Tile>> tileRotations,
                                                         Dictionary<(Edge Edge, int Id), List<Tile>> edgeIdTileMap)
        {
            foreach(var tileList in tileRotations)
            {
                foreach(var tile in tileList.Value)
                {
                    var topEdgeId = tile.EdgeIds[Edge.Top];
                    var leftEdgeId = tile.EdgeIds[Edge.Left];
                    var bottomEdgeId = tile.EdgeIds[Edge.Bottom];
                    var rightEdgeId = tile.EdgeIds[Edge.Right];

                    if (edgeIdTileMap.ContainsPairedEdge(tile.Id,
                                                         Edge.Bottom,
                                                         topEdgeId)
                        || edgeIdTileMap.ContainsPairedEdge(tile.Id,
                                                            Edge.Right,
                                                            leftEdgeId)
                        || !edgeIdTileMap.ContainsPairedEdge(tile.Id,
                            Edge.Left,
                            rightEdgeId)
                        || !edgeIdTileMap.ContainsPairedEdge(tile.Id,
                                                             Edge.Top,
                                                             bottomEdgeId)) 
                    {
                        continue;
                    }

                    yield return tile;
                }
            }
        }

        private static Dictionary<int, Tile> ParseTiles(string inputFilePath)
        {
            var tileParser = new TileParser();
            using var sr = new StreamReader(inputFilePath);

            var tiles = new Dictionary<int, Tile>();
            var tileLines = new List<string>();

            while (!sr.EndOfStream)
            {
                var line = sr.ReadLine();

                if (string.IsNullOrWhiteSpace(line))
                {
                    var tile = tileParser.Parse(tileLines);
                    tiles[tile.Id] = tile;
                    tileLines.Clear();
                    continue;
                }

                tileLines.Add(line);
            }

            if (tileLines.Any())
            {
                var lastTile = tileParser.Parse(tileLines);
                tiles[lastTile.Id] = lastTile;
                tileLines.Clear();
            }

            return tiles;
        }

        private static Dictionary<int, List<Tile>> GetTileRotations(Dictionary<int, Tile> tiles)
        {
            var tileRotations = new Dictionary<int, List<Tile>>();

            foreach (var tile in tiles.Values)
            {
                tileRotations[tile.Id] = tile.GetAllTileOrientations()
                                             .ToList();
            }

            return tileRotations;
        }

        private static Tile[][] InitializeImage(Dictionary<int, Tile> tiles)
        {
            var imageSize = (int)Math.Sqrt(tiles.Count);

            var image = new Tile[imageSize][];

            for (int i = 0;
                 i < imageSize;
                 i++)
            {
                image[i] = new Tile[imageSize];
            }

            return image;
        }

        private static Dictionary<(Edge Edge, int Id), List<Tile>> GetEdgeIdTileMap(Dictionary<int, List<Tile>> tileRotations)
        {
            var edgeIdTileMap = new Dictionary<(Edge Edge, int Id), List<Tile>>();

            foreach (var tileList in tileRotations)
            {
                foreach (var tile in tileList.Value)
                {
                    foreach (var edge in tile.EdgeIds)
                    {
                        if (!edgeIdTileMap.TryAdd((edge.Key, edge.Value),
                                                  new List<Tile>
                                                  {
                                                      tile
                                                  }))
                        {
                            edgeIdTileMap[(edge.Key, edge.Value)]
                                .Add(tile);
                        }
                    }
                }
            }

            return edgeIdTileMap;
        }
    }
}
