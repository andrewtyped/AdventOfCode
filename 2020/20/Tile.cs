using System;
using System.Collections.Generic;

using static day20.Edge;
using static day20.Orientation;

namespace day20
{
    public class Tile
    {
        #region Constructors

        public Tile(int id,
                    bool[][] rows) :this(id, rows, Orientation.Top)
        {
        }

        private Tile(int id, 
                     bool[][] rows,
                     Orientation orientation)
        {
            this.Id = id;
            this.Rows = rows;
            this.Orientation = orientation;
            this.Columns = this.Copy(this.Rows);
            this.Transpose(this.Columns);

            foreach(var edgeId in this.GetEdgeIds(this.Rows, this.Columns))
            {
                this.edgeIds[edgeId.Edge] = edgeId.Id;
            }
        }

        #endregion

        #region Instance Properties

        public bool[][] Columns
        {
            get;
        }

        public int Id
        {
            get;
        }

        public Orientation Orientation
        {
            get;
        }

        public bool[][] Rows
        {
            get;
        }

        private readonly Dictionary<Edge, int> edgeIds = new Dictionary<Edge, int>();

        public IReadOnlyDictionary<Edge, int> EdgeIds => this.edgeIds;

        #endregion

        #region Instance Methods

        private IEnumerable<(Edge Edge, int Id)> GetEdgeIds(bool[][] rows, bool[][] columns)
        {
            if(rows.Length == 0 || columns.Length == 0)
            {
                yield return (Edge.Top, 0);
                yield return (Edge.Right, 0);
                yield return (Edge.Bottom, 0);
                yield return (Edge.Left, 0);
            }

            yield return (Edge.Top, rows[0]
                                 .ToInt32());
            yield return (Edge.Right, columns[columns.Length - 1]
                                 .ToInt32());
            yield return (Edge.Bottom, rows[rows.Length - 1]
                                 .ToInt32());
            yield return (Edge.Left, columns[0]
                                 .ToInt32());
        }

        private bool[][] Copy(bool[][] input)
        {
            var copy = new bool[input.Length][];

            for(int i = 0; i < input.Length; i++)
            {
                copy[i] = new bool[input[i]
                    .Length];

                for(int j = 0; j < input[i].Length; j++)
                {
                    copy[i][j] = input[i][j];
                }
            }

            return copy;
        }

        private void Transpose(bool[][] input)
        {
            int diagonal = 0;

            for(int i = 0; i < input.Length; i++)
            {
                for (int j = 0; j < diagonal; j++)
                {
                    bool temp = input[i][j];
                    input[i][j] = input[j][i];
                    input[j][i] = temp;

                }

                diagonal++;
            }
        }

        private void Flip(bool[][] input)
        {
            foreach(var row in input)
            {
                Array.Reverse<bool>(row);
            }
        }

        private void Rotate90(bool[][] input)
        {
            this.Transpose(input);
            this.Flip(input);
        }

        public Tile FlipTile()
        {
            var rows = this.Copy(this.Rows);
            this.Flip(rows);

            var orientation = (int)this.Orientation < 4
                                  ? this.Orientation + 4
                                  : this.Orientation - 4;

            return new Tile(this.Id,
                            rows,
                            orientation);
        }

        public Tile RotateTile90()
        {
            var rows = this.Copy(this.Rows);
            this.Rotate90(rows);

            var orientation = this.Orientation switch
            {
                Orientation.Left => Orientation.Top,
                Orientation.LeftFlip => Orientation.TopFlip,
                _ => this.Orientation + 1
            };

            return new Tile(this.Id,
                            rows,
                            orientation);
        }

        public IEnumerable<Tile> GetAllTileOrientations()
        {
            yield return this;

            var rotatedTile = this.RotateTile90();
            yield return rotatedTile;
            rotatedTile = rotatedTile.RotateTile90();
            yield return rotatedTile;
            rotatedTile = rotatedTile.RotateTile90();
            yield return rotatedTile;

            var flippedTile = this.FlipTile();
            yield return flippedTile;
            rotatedTile = flippedTile.RotateTile90();
            yield return rotatedTile;
            rotatedTile = rotatedTile.RotateTile90();
            yield return rotatedTile;
            rotatedTile = rotatedTile.RotateTile90();
            yield return rotatedTile;
        }

        public Tile TrimBorder()
        {
            var newRows = new bool[this.Rows.Length - 2][];

            for(int i = 1; i < this.Rows.Length - 1; i++)
            {
                var newRow = new bool[this.Rows[i]
                                          .Length
                                      - 2];
                newRows[i - 1] = newRow;

                for(int j = 1; j < this.Rows[i].Length - 1; j++)
                {
                    newRow[j - 1] = this.Rows[i][j];
                }
            }

            return new Tile(this.Id,
                            newRows,
                            this.Orientation);
        }

        public override string ToString()
        {
            var topEdgeId = this.EdgeIds[Edge.Top];
            var leftEdgeId = this.EdgeIds[Edge.Left];
            var bottomEdgeId = this.EdgeIds[Edge.Bottom];
            var rightEdgeId = this.EdgeIds[Edge.Right];

            return $"Id: {this.Id} O: {this.Orientation} T R B L: {topEdgeId} {rightEdgeId} {bottomEdgeId} {leftEdgeId}";
        }

        #endregion
    }
}