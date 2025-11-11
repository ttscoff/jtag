# jTag

*Because you can't be too careful these days.*

**jTag** is a command line application for manipulating Jekyll tags in the YAML headers. It can perform mass operations such as tag addition, removal, merging and sorting. It can also suggest relevant tags based on the content of the post matched against your existing tag set (requires a plugin/template in your Jekyll install).

Configuration includes a persistent blacklist and synonym definitions. Tags manually added to posts are automatically whitelisted for the auto-tagger. The auto-tagger can update your posts directly, or be used to provide suggestions for a working post that you can manually insert in the post.

**NOTE:** jTag works by modifying the YAML headers of your posts directly. There's no undo. Back up your posts (which is a good idea anyway). The best way to this is with git.

If you're not already using git to manage your blog (i.e. not deploying via git), just add the non-public parts of the directory (the source files) to a repo and make a commit when you finish post. A local repo would be fine in most cases, but a remote repo offers a little extra peace of mind. Mine is set up so that a gen_deploy Rake task automatically creates a snapshot every time I publish, in addition to my own commits.


The jTag tool is at 0.1.6 at the time of this writing. It's been tested, but never used by anyone but me until today. I'll be adding features and updating as I go, so please [let me know about bugs][support].

First, though, let's cover the plugin side, which hasn't needed to change since I first wrote it. Set it up and forget it.

## Generating a tag index

To use jtag, we need to generate an index of all the tags on a Jekyll/OctoPress blog in JSON format. I chose JSON because it could be used in JavaScript apps easily and would make the data useful for more than just jTag. The code for both the template and the plugin can be found in the [Jekyll folder of the GitHub repository](https://github.com/ttscoff/jtag/tree/master/Jekyll).

### Plugin: autotag_gen.rb

This plugin is a Page generator which creates `/data/tags.json`, which is a list of all the tags on your blog, as well as a list of the top 50 tags with a count of how many times they appear across your blog. You can [download the plugin here](https://github.com/ttscoff/jtag/blob/master/Jekyll/plugins/autotag_gen.rb).

The plugin looks for the `tags_json.html` template in your _layouts folder. See the example provided. It provides the following, which can be used in the liquid template:

- `page.json_tags`
- `page.json_tags_count`

In your blog's `_config.yml`, you can optionally add rules for excluding tags or using an alternate destination:

- `tag_excludes:` array of tags to exclude from all listings
- `tags_json_dir:` alternate folder for the `data.json` file. Set to blank for root, defaults to 'data'

Side note: if you're also using tags.json with JavaScript on your site, be sure you have the proper headers defined in `.htaccess`:


    AddType application/json               json
    ExpiresByType application/json         "access plus 0 seconds"

### Template: tags_json.html

Place [the template](https://github.com/ttscoff/jtag/blob/master/Jekyll/source/_layouts/tags_json.html) in `source/_layouts/tags_json.html`.

Now you can do a full build of your blog and the `data/tags.json` file will be ready for deploy.

## jTag

jTag is currently at version 0.1.6 It will be a work in progress for a while as I make it more efficient and figure out the best ways to integrate it into my blogging workflow.It grabs all of the tags on your blog (the `tags.json` file) and compares them to the text you give it. It handles matching plurals and different conjugations of words so that you get tag results even if they're not an exact match.

### Installation/Configuration

The gem is hosted on [rubygems.org](https://rubygems.org/gems/jtag). To install, either add the jtag dependency to your Gemfile in your Jekyll folder (`gem "jtag", "~> 0.1.6"`) and run `bundle`, or run `gem install jtag`. If you're not using a ruby version manager, you may need to use `sudo gem install jtag` to install it in your system Ruby configuration.

Run `jtag config` to ensure it's loaded and create the configuration folder and files in `~/.config/jtag`.

The only configuration option required is the location (url without protocol) of your `tags.json` file. It's set in `~/.config/jtag/config.yml`:

    tags_location: brettterpstra.com/data/tags.json

There are three other files that are generated in `~/.config/jtag/`, and they can be edited as needed:

- **blacklist.txt**

    This is a blacklist. Tags in this list will never show up in automatic results. If it already exists in the post it's merged in, but it won't be created. There are some tags that are relatively generic in terminology and would be triggered on almost every post. They're usually tags that I'd enter myself anyway. For example, I have a tag for Gabe Weatherhead's show, [Generational]([70decibels]): "generational." Because jTag stems the word before scanning for it, anything based off the root "generi" will trigger that tag. Thus, it's blacklisted and added manually on the infrequent occasions that I'm on the show.

    The easiest way to add a tag to the blacklist is to run `jtag blacklist TAGNAME`. You can blacklist multiple tags at once, just separate them with a space. The blacklist is stored in `~/.config/jtag/blacklist.txt` and can be edited manually if needed.
- **stopwords.txt**

    This is a predefined list of common words that will most likely never be tags. They're "stemmed" down to their root, so that "thing," "things," and "thingy" are all blocked by one line. If you find your results are missing a particular tag, scan the `~/.config/jtag/stopwords.txt` file for the culprit.
- **synonyms.yml**

    The `synonyms.yml` file is a YAML file that defines alternate spellings, punctuations or related topics which determine when a tag is used. For example, my tag for Mountain Lion is "mountainlion" because I like single-word, lowercase tags. That isn't going to be found in the text of my posts, though, so I add synonyms like this:


        mountainlion:
        - Mountain Lion
        - 10.8
        - OS X 10.8


    You can add as many as you like. When an attached term is found in the text, it will include the parent tag.

## Usage

**Note:** jTag requires that YAML headers exist in the post being processed. I may add the option to pass just content text and get back an appropriate auto-tag response, but for now you at least need a yaml `---` header and terminator.

jTag is built using subcommands, each with it's own options and parameters. You can get help for jTag with `jtag help`, and documentation for each command with `jtag help command`.

### Commands

    jtag [-t] command [options] [arguments] filename(s)

    help      - Shows a list of commands or help for one command

    add       - Add tags to post(s)
    remove    - Remove tags from post(s)
    merge     - Merge multiple tags into one

    config    - Update and notify user of configuration files location
    blacklist - Blacklist a specific tag

    search      - List all tags, optionally filter for keywords/regular expressions (boolean OR search)
    sort      - Sort the existing tags for posts
    tag       - Generate a list of recommended tags, optionally updating the file
    tags      - Show the current tags for posts

Use the global `-t` option with jTag to run it in "test" mode. No files will be overwritten if the command starts with `jtag -t (command)`. All results will be written to STDOUT for inspection. If you run it with `-t` and pass `-f fmt` to relevant commands with a single file argument, it will output just the tag results in your selected format. This makes it possible to script jTag into other applications.

`config`
: Use **config** to install configuration files, replace missing ones, or reset to defaults (--reset).

`blacklist`
: Use **blacklist** to quickly add or remove (run with `-r`) a tag from the blacklist.

`add`
: Use **add** on a single file, a glob pattern or the results of a grep, ack or find command (using xargs) to add one or more tags to the specified posts. With this, you can quickly add tags to an individual post, or add a tag to any posts that contain certain words in its content or title.

        find source/_posts -name "*marky*" | xargs jtag add markdownifier

`remove`
: Use **remove** to remove tags on select files, or run it on an entire folder to purge tags from your system.

`merge`
: You can use **merge** to prune your taxonomy. Have two tags that only differ by capitalization or pluralization? Run something like `jtag merge Markdown markdown _posts/*.md` and all instances of "Markdown" will be converted to "markdown," avoiding duplicates should they arise. You can merge as many tags as you want, the last one in the list will be the one that replaces them all.

`search`
: Use **search** to list all of the tags on your blog, optionally filtering the list with a keyword as the argument. Multiple keywords will be combined in an boolean OR fashion, so any tags that match any of the keywords will be returned. Keywords can also be quoted regular expressions (e.g. "^mark" to find only tags that _start_ with "mark").

Add the **-c** option to get tags back with a number representing how many posts they appear in. This command is a tool to help you find the proper punctuation, capitalization and pluralization of existing tags to ensure consistency.

        $ jtag search -f list markdown
        markdown
        multimarkdown
        markdownservices
        markdownifier
        markdownediting
        markdownrules

`tag`
: Use **tag** to suggest tags for your post based on its content. Suggested tags will be mixed with any existing tags (which are automatically whitelisted) and it will return a YAML array block to add to your post. By default, it will write the tags to the file automatically. If you use the -t global switch (`jtag -t tag post.md`) it will just give you the output (in YAML by default) and let you copy/paste it.

`tags`
: Use **tags** to see the current tags on a post or posts. They'll be listed with the filename as a header and the tags below. This is just handy for quickly confirming operations.

`sort`
: The **sort** command is a convenience method to alphabetize the tags in your post. It can safely be run on your entire `_posts` folder just to tidy things up.

Any command that outputs a list of tags has the option (`-f, --format`)to change the format to one of `csv`, `list` (plain text), `json` or `yaml` (default). Hopefully this will provide some scripting and integration options in the future.

### Bash completion

If you're interested, there's also a quick script you can drop into `.bash_profile` and get [jtag tab-completion in Bash](https://github.com/ttscoff/jtag/blob/master/jtag.completion.bash).

[support]: https://github.com/ttscoff/jtag/issues/


![](http://cdn3.brettterpstra.com/uploads/2013/08/jtag.jpg)
