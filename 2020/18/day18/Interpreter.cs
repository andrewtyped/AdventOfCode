using System;
using System.Collections.Generic;
using System.Text;

using static day18.TokenType;

namespace day18
{
    public class Interpreter
    {
        public long Interpret(Expr expr)
        {
            return expr switch
            {
                MathExpr mathExpr => this.Evaluate(mathExpr),
                LiteralExpr literalExpr => this.Evaluate(literalExpr),
                GroupExpr groupExpr => this.Evaluate(groupExpr),
                _ => throw new Exception($"Unrecognized expr type {expr}")
            };
        }

        private long Evaluate(MathExpr mathExpr)
        {
            var left = this.Interpret(mathExpr.Left);
            var right = this.Interpret(mathExpr.Right);

            return mathExpr.Op.TokenType switch
            {
                Plus => left + right,
                Star => left * right,
                _ => throw new Exception($"Unrecognized token type {mathExpr.Op.TokenType}")
            };
        }

        private long Evaluate(LiteralExpr literalExpr)
        {
            return literalExpr.Token.Value.Value;
        }

        private long Evaluate(GroupExpr groupExpr)
        {
            return this.Interpret(groupExpr.Inner);
        }
    }
}
