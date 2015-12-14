findFirst(array, func)
Find the first element in the array which returns true when passed to func.

inputs:
    array: the array to search
    func: the function to pass each array element to
        func arguments are (e, i, a)
        e - the current array element
        i - the current array index
        a - the array itself

output:
    the first element of array at which func returns true
    or null

Example usage:
    var people = [
        { name: "John", age: 25 },
        { name: "Sally", age: 40 },
        { name: "Bob", age: 77 },
        { name: "Jenifer", age: 12}
    ]

    // Returns { name: "Sally", age: 40 }
    findFirst(people, function(person) {
        return person.age > 30;
    });

function findFirst(array, func) {
    if (array instanceof Array)
        for (var i = 0; i < array.length; i++)
            if (func(array[i]), i, array)
                return array[i];

    return null;
}
