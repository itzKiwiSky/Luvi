package comma;

import comma.ValueDefinition;
import haxe.io.Eof;
import comma.Style;

class CliApp {
    var commands = new Array<Command>();
    var appName = "";
    var version = "";
    var defaultCommand:Command;
    var executeDefaultCommandOnly = false;

    public function new(appName:String, version:String, executeDefaultCommandOnly = false) {
        this.appName = appName;
        this.version = version;
        this.executeDefaultCommandOnly = executeDefaultCommandOnly;
    }

    public function getDefaultCommand() {
        if (defaultCommand == null) {
            if (commands.length == 0) {
                throw("No default command is set and no command registered");
            }
            return commands[0];
        }
        return defaultCommand;
    }

    function getCommandOfName(name:String) {
        for (c in commands) {
            if (c.getName() == name) {
                return c;
            }
        }
        return null;
    }

    function hasCommandOfName(name:String) {
        for (c in commands) {
            if (c.getName() == name) {
                return true;
            }
        }
        return false;
    }

    public function setDefaultCommand(command:Command) {
        defaultCommand = command;
    }

    public function addCommand(command:Command) {
        commands.push(command);
    }

    public function removeCommand(command:Command) {
        commands.remove(command);
    }

    public function start() {
        executeInternal(Sys.args());
    }

    public function execute(command:String){
        var args = command.split(" ");
        args.push(Sys.getCwd());
        executeInternal(args);
    }

    function executeInternal(args:Array<String>) {
        //var cwd = args.pop();
        var options = ParsedOptions.parse(args);
        var values = parseValues(args);
        var arguments = "";

        //Sys.setCwd(cwd);

        if (executeDefaultCommandOnly) {
            getDefaultCommand().execute(this, values, options);
            return;
        }
        if (args.length == 0) {
            printHelp();
            return;
        }

        var cm = args[0];
        if (cm.charAt(0) == "-") {
            printHelp();
            return;
        }
        if (hasCommandOfName(cm)) {
            getCommandOfName(cm).execute(this, values, options);
        } else {
            println("Command not found: " + cm);
        }
    }

    function parseValues(args: Array<String>) {
        var ret = new Array<String>();
        for (i in 1...args.length) {
            var val = args[i];
            if (val.charAt(0) == "-")
                return ret;
            ret.push(val);
        }
        return ret;
    }

    public function println(message:Dynamic) {
        Sys.println(message);
    }

    public function print(message:Dynamic) {
        Sys.print(message);
    }

    public function prompt(message:String = "") {
        print(message + ": ");
        return Sys.stdin().readLine();
    }

    public function printHelp() 
    {
        Main.displayLogo();

        println("A helpful help :)");
        if (commands.length > 0) 
        {
            println("Commands:");

            var table = Table.create();
            for (c in commands) 
            {
                if (c.getName() == "")
                    continue;

                table.addRow();
                table.addColumn(c.getName());
                table.addEmptyColumn(10);
                table.addColumn(c.getDescription());

                var argCount = Lambda.count(c.arguments);

                if (argCount > 0)
                {
                    for (name => desc in c.arguments)
                    {
                        table.addRow();
                        table.addColumn(Style.space(4) + '<${name}>');
                        table.addEmptyColumn(4);
                        table.addColumn(desc);
                    }
                    table.addRow();
                }
                if (c.getOptionDefinitions().length > 0) 
                {
                    table.addRow();
                    for (optDef in c.getOptionDefinitions()) 
                    {
                        var optDefNameColumn = "-" + optDef.getName();
                        if (optDef.getAlias() != "") 
                            optDefNameColumn += " --" + optDef.getAlias();
                        table.addColumn(Style.space(4) + optDefNameColumn);
                        table.addEmptyColumn(4);
                        table.addColumn(optDef.getDescription());
                        table.addRow();
                    }
                }

            }
            Sys.println(table.toString(1));
        }
    }
}
