#include "chplrt.h"

#include "arg.h"
#include "chplcast.h"
#include "chplcgfns.h"
#include "chplexit.h"
#include "chplio.h"
#include "chpl-mem.h"
#include "chplmemtrack.h"
#include "chpl-tasks.h"
#include "config.h"
#include "error.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


static int gdbFlag = 0;
int32_t blockreport = 0; // report locations of blocked threads on SIGINT
int32_t taskreport = 0;  // report thread hierarchy on SIGINT

int _runInGDB(void) {
  return gdbFlag;
}

static void printHeaders(char thisType, char* lastType) {
  if (thisType != *lastType) {
    fprintf(stdout, "\n");
    switch (thisType) {
    case 'c':
      fprintf(stdout, "CONFIG VAR FLAGS:\n");
      fprintf(stdout, "=================\n");
      break;

    case 'g':
      fprintf(stdout, "FLAGS:\n");
      fprintf(stdout, "======\n");
      break;
    }
    *lastType = thisType;
  }
}


void printHelpTable(void) {
  typedef struct _flagType {
    const char* flag;
    const char* description;
    const char headerType;
  } flagType;

  static flagType flagList[] = {
    {"-h, --help", "print this message", 'g'},
    {"-a, --about", "print compilation information", 'g'},
    {"-nl <n>", "run program using n locales", 'g'},
    {"", "(equivalent to setting the numLocales config const)", 'g'},
    {"-q, --quiet", "run program in quiet mode", 'g'},
    {"-v, --verbose", "run program in verbose mode", 'g'},
    {"-b, --blockreport", "report location of blocked threads on SIGINT", 'g'},
    {"-t, --taskreport",
     "report list of pending and executing tasks on SIGINT", 'g'},
    {"--gdb", "run program in gdb", 'g'},
    {"-E<name=value>", "set the value of an environment variable", 'g'},

    {"-s, --<cfgVar>=<val>", "set the value of a config var", 'c'},    
    {"-f<filename>", "read in a file of config var assignments", 'c'},

    {NULL, NULL, ' '}
  };

  int i = 0;
  int longestFlag = 0;
  char lastHeaderType = '\0';

  printAdditionalHelp();

  while (flagList[i].flag) {
    int thisFlag = strlen(flagList[i].flag);
    if (longestFlag < thisFlag) {
      longestFlag = thisFlag;
    }
    i++;
  }

  i = 0;
  while (flagList[i].flag) {
    printHeaders(flagList[i].headerType, &lastHeaderType);
    if (flagList[i].flag[0] == '\0') {
      fprintf(stdout, "  %-*s    %s\n", longestFlag, flagList[i].flag,
              flagList[i].description);
    } else {
      fprintf(stdout, "  %-*s  : %s\n", longestFlag, flagList[i].flag, 
              flagList[i].description);
    }
    i++;
  }
  fprintf(stdout, "\n");
}


static int32_t _argNumLocales = 0;

void parseNumLocales(const char* numPtr, int32_t lineno, c_string filename) {
  int invalid;
  char invalidChars[2] = "\0\0";
  _argNumLocales = c_string_to_int32_t_precise(numPtr, &invalid, invalidChars);
  if (invalid) {
    char* message = chpl_glom_strings(3, "\"", numPtr, 
                                      "\" is not a valid number of locales");
    chpl_error(message, lineno, filename);
  }
  if (_argNumLocales < 1) {
    chpl_error("Number of locales must be greater than 0", lineno, filename);
  }
}

int32_t getArgNumLocales(void) {
  int32_t retval = 0;
  if (_argNumLocales) {
    retval = _argNumLocales;
  }
  return retval;
}


extern void chpl_program_about(void); // The generated code provides this


static void defineEnvVar(const char* estr, int32_t lineno, c_string filename) {
  //
  // Note that you must pass a writable string to defineEnvVar(),
  // because it relies on being able to replace the internal '='
  // with a '\0' in order to have separate name and value strings
  // to pass to setenv(3), which duplicates those.
  //
  static char errmsg[1000];
  char* estr_val;

  if ((estr_val = strchr(estr, '=')) == NULL) {
    chpl_error("-E argument must be of the form name=value", lineno, filename);
  }

  *estr_val = '\0';
  if (setenv(estr, estr_val + 1, 0) != 0) {
    snprintf(errmsg, sizeof(errmsg),
             "Cannot setenv(\"%s\"): %s", estr, strerror(errno));
  }
  *estr_val = '=';
}


void parseArgs(int* argc, char* argv[]) {
  int i;
  int printHelp = 0;
  int printAbout = 0;
  int origargc = *argc;
  int stop_parsing = 0;

  for (i = 1; i < *argc; i++) {
    const char* filename = "<command-line arg>";
    int lineno = i + (origargc - *argc);
    int argLength = 0;
    const char* currentArg = argv[i];
    argLength = strlen(currentArg);

    if (mainHasArgs && (stop_parsing || argLength < 2)) {
      /* update the argv structure passed to a Chapel program, but don't parse
       * the arguments
       */
      chpl_gen_main_arg.argv[chpl_gen_main_arg.argc] = argv[i];
      chpl_gen_main_arg.argc++;
      continue;
    }

    /* if the Chapel main takes arguments, then "--" is a magic argument that
     * will prevent parsing of any additional arguments
     */
    if (mainHasArgs && strcmp(currentArg, "--") == 0) {
      stop_parsing = 1;
      continue;
    }

    if (argLength < 2) {
      const char* message = chpl_glom_strings(3, "\"", currentArg, 
                                              "\" is not a valid argument");
      chpl_error(message, lineno, filename);
    }

    switch (currentArg[0]) {
    case '-':
      switch (currentArg[1]) {
      case '-':
        {
          const char* flag = currentArg + 2;

          if (strcmp(flag, "gdb") == 0) {
            gdbFlag = i;
            break;
          }
            
          if (strcmp(flag, "help") == 0) {
            printHelp = 1;
            chpl_gen_main_arg.argv[chpl_gen_main_arg.argc] = "--help";
            chpl_gen_main_arg.argc++;
            break;
          }
          if (strcmp(flag, "about") == 0) {
            printAbout = 1;
            break;
          }
          if (strcmp(flag, "verbose") == 0) {
            verbosity=2;
            break;
          }
          if (strcmp(flag, "blockreport") == 0) {
            blockreport = 1;
            break;
          }
          if (strcmp(flag, "taskreport") == 0) {
            taskreport = 1;
            break;
          }
          if (strcmp(flag, "quiet") == 0) {
            verbosity = 0;
            break;
          }
          if (argLength < 3) {
            char* message = chpl_glom_strings(3, "\"", currentArg, 
                                              "\" is not a valid argument");
            chpl_error(message, lineno, filename);
          }
          i += handlePossibleConfigVar(argc, argv, i, lineno, filename);
          break;
        }

      case 'a':
        if (currentArg[2] == '\0') {
          printAbout = 1;
        } else {
          i += handleNonstandardArg(argc, argv, i, lineno, filename);
        }
        break;

      case 'b':
        if (currentArg[2] == '\0') {
          blockreport = 1;
        } else {
          i += handleNonstandardArg(argc, argv, i, lineno, filename);
        }
        break;

      case 'E':
        if (currentArg[2] == '\0') {
          i++;
          if (i >= *argc) {
            chpl_error("-f flag is missing <filename> argument", 
                       lineno, filename);
          }
          currentArg = argv[i];
          defineEnvVar(currentArg, lineno, filename);
        } else {
          defineEnvVar(currentArg + 2, lineno, filename);
        }
        break;

      case 'f':
        if (currentArg[2] == '\0') {
          i++;
          if (i >= *argc) {
            chpl_error("-f flag is missing <filename> argument", 
                       lineno, filename);
          }
          currentArg = argv[i];
          parseConfigFile(currentArg, lineno, filename);
        } else {
          parseConfigFile(currentArg + 2, lineno, filename);
        }
        break;

      case 'h':
        if (currentArg[2] == '\0') {
          printHelp = 1;
          chpl_gen_main_arg.argv[chpl_gen_main_arg.argc] = "-h";
          chpl_gen_main_arg.argc++;
        } else {
          i += handleNonstandardArg(argc, argv, i, lineno, filename);
        }
        break;

      case 'n':
        if (currentArg[2] == 'l') {
          const char* numPtr;
          if (currentArg[3] == '\0') {
            i++;
            if (i >= *argc) {
              chpl_error("-nl flag is missing <numLocales> argument", 
                         lineno, filename);
            }
            currentArg = argv[i];
            numPtr = currentArg;
          } else {
            numPtr = &(currentArg[3]);
          }
          initSetValue("numLocales", numPtr, "Built-in", lineno, filename);
          break;
        }
        i += handleNonstandardArg(argc, argv, i, lineno, filename);
        break;

      case 'q':
        if (currentArg[2] == '\0') {
          verbosity = 0;
        } else {
          i += handleNonstandardArg(argc, argv, i, lineno, filename);
        }
        break;

      case 's':
        {
          if (argLength < 3) {
            char* message = chpl_glom_strings(3, "\"", currentArg, 
                                              "\" is not a valid argument");
            chpl_error(message, lineno, filename);
          }
          i += handlePossibleConfigVar(argc, argv, i, lineno, filename);
          break;
        }

      case 't':
        if (currentArg[2] == '\0') {
          taskreport = 1;
        } else {
          i += handleNonstandardArg(argc, argv, i, lineno, filename);
        }
        break;

      case 'v':
        if (currentArg[2] == '\0') {
          verbosity = 2;
        } else {
          i += handleNonstandardArg(argc, argv, i, lineno, filename);
        }
        break;

      default:
        i += handleNonstandardArg(argc, argv, i, lineno, filename);
        break;
      }
      break;

    default:
      i += handleNonstandardArg(argc, argv, i, lineno, filename);
      break;
    }
  }

  if (printAbout) {
    chpl_program_about();
    chpl_exit_any(0);
  }

  if (printHelp) {
    if (!mainHasArgs) {
      printHelpTable();
      printConfigVarTable();
      chpl_exit_any(0);
    }
  }
}


int chpl_specify_locales_error(void) {
  chpl_error("Specify number of locales via -nl <#> or --numLocales=<#>", 0, 0);
  return 0;
}
