using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace day18
{
    class Program
    {
        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day18.exe "".\path\to\inputfile.txt""");
            }

            using var reader = new StreamReader(args[0]);

            var evaluations = new List<long>();
            var evaluationsPhase2 = new List<long>();

            while (!reader.EndOfStream)
            {
                var source = reader.ReadLine();
                Console.WriteLine($"Evaluating {source}");
                var scanner = new Scanner();
                var tokens = scanner.Scan(source);
                var parser = new Parser();
                var parserPhase2 = new ParserPhase2();
                var expr = parser.Parse(tokens);
                var exprPhase2 = parserPhase2.Parse(tokens);
                var interpreter = new Interpreter();
                var evaluation = interpreter.Interpret(expr);
                var evaluationPhase2 = interpreter.Interpret(exprPhase2);
                evaluations.Add(evaluation);
                evaluationsPhase2.Add(evaluationPhase2);
            }

            foreach(var evaluation in evaluations)
            {
                Console.WriteLine(evaluation);
            }

            var sum = evaluations.Sum();

            Console.WriteLine($"======== PHASE 2 ===========");

            foreach(var evaluation in evaluationsPhase2)
            {
                Console.WriteLine(evaluation);
            }

            var sumPhase2 = evaluationsPhase2.Sum();

            Console.WriteLine($"Sum of evaluations phase 1: {sum}");
            Console.WriteLine($"Sum of evaluations phase 2: {sumPhase2}");
        }
    }
}
