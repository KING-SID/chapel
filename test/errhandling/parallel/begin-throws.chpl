use ExampleErrors;

proc test() {
  try {
    writeln("before sync block");
    sync {
      begin {
        throw new owned StringError("test error");
      }
      begin {
        throw new owned StringError("test error");
      }
    }
    writeln("after sync block");
  } catch errors: TaskErrors {
    for e in errors { 
      writeln("Caught group error e ", e.message());
    }
  } catch e {
    writeln("Caught other error ", e.message());
  }
}

test();
