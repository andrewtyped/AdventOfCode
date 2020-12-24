using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace day21
{
    class Food
    {
        public readonly HashSet<string> Ingredients = new HashSet<string>();

        public readonly HashSet<string> Allergens = new HashSet<string>();

        public IEnumerable<(string Allergen, string Ingredient)> GetAllergenIngredientPairs()
        {
            foreach(var allergen in Allergens)
            {
                foreach(var ingredient in Ingredients)
                {
                    yield return (allergen, ingredient);
                }
            }
        }

        public static Food Parse(string input)
        {
            var food = new Food();
            var ingredientAllergenSplit = input.Split('(');

            ParseIngredients(food,
                             ingredientAllergenSplit[0]);

            if(ingredientAllergenSplit.Length == 2)
            {
                ParseAllergens(food,
                               ingredientAllergenSplit[1]);
            }

            return food;
        }

        private static void ParseIngredients(Food food, string ingredients)
        {
            var sb = new StringBuilder();
            foreach(var character in ingredients)
            {
                if(character == ' ' && sb.Length > 0)
                {
                    food.Ingredients.Add(sb.ToString());
                    sb.Clear();
                    continue;
                }

                if(character >= 'a' && character <= 'z')
                {
                    sb.Append(character);
                }
            }

            if(sb.Length > 0)
            {
                food.Ingredients.Add(sb.ToString());
            }
        }

        private static void ParseAllergens(Food food, string allergens)
        {
            var sb = new StringBuilder();
            foreach(var character in allergens)
            {
                if(character == ' ' && sb.Length > 0)
                {
                    food.Allergens.Add(sb.ToString());
                    sb.Clear();
                    continue;
                }

                if(character >= 'a' && character <= 'z')
                {
                    sb.Append(character);
                }
            }

            if(sb.Length > 0)
            {
                food.Allergens.Add(sb.ToString());
            }

            food.Allergens.Remove("contains");
        }
    }
    class Program
    {
        static void Main(string[] args)
        {
            if(args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day21.exe "".\path\to\input.txt""");
            }

            using var sr = new StreamReader(args[0]);

            var foods = new List<Food>();

            while (!sr.EndOfStream)
            {
                foods.Add(Food.Parse(sr.ReadLine()));
            }

            var allergenFoodMap = GetAllergenFoodMap(foods);
            var allergenPossibleIngredientMap = GetAllergenPossibleIngredientMap(allergenFoodMap);
            var allergenIngredients = GetAllergenIngredients(allergenPossibleIngredientMap);
            var ingredientCounts = GetIngredientCounts(foods);
            var nonAllergenIngredientCount = GetNonAllergenIngredientCount(allergenIngredients,
                                                                           ingredientCounts);
            Console.WriteLine($"Non-allergen ingredient count: {nonAllergenIngredientCount}");

            var exactAllergens = GetExactAllergens(allergenPossibleIngredientMap);
            var formattedAllergens = string.Join(",",
                                                 exactAllergens.OrderBy(allergenIngredientPair => allergenIngredientPair.Allergen)
                                                               .Select(allergenIngredientPair => allergenIngredientPair.Ingredient));
            Console.WriteLine($"Exact allergens: {formattedAllergens}");
        }

        private static List<(string Allergen, string Ingredient)> GetExactAllergens(IDictionary<string, List<string>> allergenPossibleIngredientMap)
        {
            var exactAllergens = new List<(string Allergen, string Ingredient)>();
            string ingredientToRemove = null;
            while(allergenPossibleIngredientMap.Count > 0)
            {
                foreach(var allergen in allergenPossibleIngredientMap.Keys.ToList())
                {
                    var ingredients = allergenPossibleIngredientMap[allergen];

                    if(ingredients.Count == 1)
                    {
                        exactAllergens.Add((allergen, ingredients[0]));
                        ingredientToRemove = ingredients[0];
                        break;
                    }
                }

                if (ingredientToRemove != null)
                {
                    foreach (var allergen in allergenPossibleIngredientMap.Keys.ToList())
                    {
                        var ingredients = allergenPossibleIngredientMap[allergen];

                        if (ingredientToRemove != null)
                        {
                            ingredients.Remove(ingredientToRemove);
                        }

                        if (ingredients.Count == 0)
                        {
                            allergenPossibleIngredientMap.Remove(allergen);
                        }
                    }
                }
                
                ingredientToRemove = null;
            }

            return exactAllergens;
        }

        private static int GetNonAllergenIngredientCount(HashSet<string> allergenIngredients, 
                                                         IDictionary<string, int> ingredientCounts)
        {
            int nonAllergenIngredientCount = 0;

            foreach(var ingredientCount in ingredientCounts)
            {
                if (allergenIngredients.Contains(ingredientCount.Key))
                {
                    continue;
                }

                nonAllergenIngredientCount += ingredientCount.Value;
            }

            return nonAllergenIngredientCount;
        }

        private static IDictionary<string, int> GetIngredientCounts(List<Food> foods)
        {
            var ingredientCounts = new ConcurrentDictionary<string, int>();

            Parallel.ForEach(foods,
                             food =>
                             {
                                 foreach(var ingredient in food.Ingredients)
                                 {
                                     ingredientCounts.AddOrUpdate(ingredient,
                                                                  1,
                                                                  (existingIngredient,
                                                                   count) => count + 1);
                                 }
                             });

            return ingredientCounts;
        }

        private static HashSet<string> GetAllergenIngredients(IDictionary<string, List<string>> allergenPossibleIngredientMap)
        {
            var allergenIngredients = new HashSet<string>();

            foreach(var allergenIngredientKvp in allergenPossibleIngredientMap)
            {
                foreach(var ingredient in allergenIngredientKvp.Value)
                {
                    allergenIngredients.Add(ingredient);
                }
            }

            return allergenIngredients;
        }

        private static IDictionary<string, List<string>> GetAllergenPossibleIngredientMap(IDictionary<string, List<Food>> allergenFoodMap)
        {
            var allergenPossibleIngredientMap = new ConcurrentDictionary<string, List<string>>();

            Parallel.ForEach(allergenFoodMap,
                             allergenFoodsKvp =>
                             {
                                 IEnumerable<string> possibleFoods = default;
                                 var foods = allergenFoodsKvp.Value;

                                 for (int i = 0; i < foods.Count; i++)
                                 {
                                     if(i == 0)
                                     {
                                         possibleFoods = foods[0].Ingredients;
                                     }
                                     else
                                     {
                                         possibleFoods = possibleFoods.Intersect(foods[i]
                                                                                     .Ingredients);
                                     }
                                 }

                                 allergenPossibleIngredientMap.TryAdd(allergenFoodsKvp.Key,
                                                                      possibleFoods.ToList());
                             });

            return allergenPossibleIngredientMap;
        }

        static IDictionary<string, List<Food>> GetAllergenFoodMap(List<Food> foods)
        {
            var allergenFoodMap = new ConcurrentDictionary<string, List<Food>>();

            Parallel.ForEach(foods,
                             food =>
                             {
                                 foreach (var allergen in food.Allergens)
                                 {
                                     allergenFoodMap.AddOrUpdate(allergen,
                                                                 new List<Food>
                                                                 {
                                                                     food
                                                                 },
                                                                 (allergen,
                                                                  foodsList) =>
                                                                 {
                                                                     foodsList.Add(food);
                                                                     return foodsList;
                                                                 });
                                 }
                             });
            return allergenFoodMap;
        }
    }
}
