// Test the _max(type) primitive.

var i8:int(8);
var i16:int(16);
var i32:int(32);
var i64:int;
writeln( _max( i8.type));
writeln( _max( i16.type));
writeln( _max( i32.type));
writeln( _max( i64.type));
writeln( _max( int.type));

var ui8:uint(8);
var ui16:uint(16);
var ui32:uint(32);
var ui64:uint;
writeln( _max( ui8.type));
writeln( _max( ui16.type));
writeln( _max( ui32.type));
writeln( _max( ui64.type));
writeln( _max( uint.type));

var f32:float(32);
var f64:float;
writeln( _max( f32.type));
writeln( _max( f64.type));
writeln( _max( float.type));

