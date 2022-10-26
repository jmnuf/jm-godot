# JM Godot Tools & Stuff

DISCLAIMER: This has been done and will be worked on as a side project, have a good one!

A repo with random classes, scripts, and tools that I've made.

My philosophy is to avoid extending `Node` classes as much as possible so most of what's made here will probably be made so you wrap it around a node that does something with the provided class or you extend the class to expand for your use-case. I'm not saying using `Node` based classes is bad, I just think that these generics mostly will be as utilities that could be interacting with other systems. I don't feel like most of this should be a `Node` and if we disagree let's agree to disagree, it's just design preferences. If you don't like it copy paste the code into your own script that extends `Node` and fix the issues that may arrise from that, be free just how Open Source is.
If you do use anything here, know that you are free to edit as you please.

## JSerializes

The class `JSerializes` extends `Reference` and is serializable to a JSON for later Godot importing mostly, for now!
You can write any class that inherits from this and can be serialized with the `string` or `dict` method.
Truthfully `string()` just calls `JSON.print(dict())` so it's whatever you need at the moment

To deserialize the data you can use `JDeserializer.parse` which can take in either a Dictionary or a JSON string.
Will return null if it failed to parse but will show some errors on your console unless there's an issue while parsing that I didn't predict or ignored in that cases app crashes. Still you can try and guess why your data sucked and didn't get parsed and then file a complain that will probably fall to my tone deaf ears so might take me a moment to get what you mean.

Under the hood this is just using the `inst2dict` and `dict2inst` functions provided by Godot and wrapping over them to handle some edge cases though it isn't a solve all so don't think that you can basically store whatever in this. You can store more `JSerializes` instances inside of one another so infinite nesting of these should be possible in theory though performance probably drops significantly cause my handling of things is relatively subobptimal most likely and best way to get this to be better would be to do it in GDNative cause that's faster I've read somewhere I think but I'm lazy to confirm and reform so screw that.

## JDataTable

The class `JDataTable` extends from `JSerializes` and stores data while following a provided model or just `JSerializes` (This might change to a separate class that inherits from that) is used as a model which means it's whatever shape you initialize the object as with a dictionary with the option to just keep adding more params like a dictionary since `JSerializes._extras` consumes any non-existent properties when using `.set(property, value)` but if you try to set a property that wasn't declared with `set` then the class will error out as it's not part of its object shape. So using `set` is like expanding the shape of the object but apart from that it adheres strictly to the given shape.
If you're handling just one set of data then this could be enough if you want something slightly bigger than a Dictionary of Dictionaries with data consistency that serializes outside of `Resources` because you need to send this data to a non-Godot server that expects JSON.

## JDatabase

The class `JDatabase` (DB) extends from `JSerializes` and stores `JDataTable`(table) instances in a Dictionary and is able to query any table for data or subdata and also edit such data.
In the future the ability to link a table in a DB to another table in that same or another DB will be added!

## JDataHandler

Plugin script adds a global singleton JDH which can hold a set of serializable databases. Truly this is just if you want to use the default setup of databases which could work just fine for basic need of simple separate data systems. If you don't need more than one `JDatabase` then you're better off making another singleton that has exactly on that one DB to use and manipulate. This is the only class of the Serialize section that's doesn't extend `Reference` as the base Godot class, since everything else is made with the idea of keeping simple for managing and also I discourage having a `Node` for each piece of this data handling structure.
