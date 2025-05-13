class Command::ChatQuery < Command
  store_accessor :data, :query, :params

  def title
    "Chat query '#{query}'"
  end

  def execute
    response = chat.ask query
    generated_commands = replace_names_with_ids(JSON.parse(response.content)).tap do |commands|
      Rails.logger.info "*** #{commands}"
    end
    build_chat_response_with generated_commands
  end

  private
    def chat
      chat = RubyLLM.chat
      chat.with_instructions(prompt)
    end

    # TODO:
    #   - Don't generate initial /search if not requested. "Assign to JZ" should
    def prompt
      <<~PROMPT
        You are Fizzy’s command translator. Read the user’s request, consult the current view, and output a **single JSON array** of command objects.  
        Return **nothing except that JSON** so it can be copy‑pasted directly.

        --------------------------------------------------------------------
        CURRENT VIEW  
        #{context.viewing_card_contents? ? "inside a card" : "viewing a list of cards"}
        --------------------------------------------------------------------

        AVAILABLE COMMANDS  

        | Action                              | Syntax & Examples                                    | Extra keys allowed? |
        |-------------------------------------|------------------------------------------------------|---------------------|
        | Assign users to a card              | `/assign  <user>`  — `/assign kevin`                 | No                  |
        | Close a card                        | `/close  [reason]`  — `/close` · `/close not now`    | No                  |
        | Tag a card                          | `/tag    <tag>`   — `/tag performance`               | No                  |
        | Clear all filters                   | `/clear`                                             | No                  |
        | Get insight about cards (default)   | `/insight <query>` — `/insight summarize latency`    | No                  |
        | Search cards (with filters)         | `/search` + params (see below)                       | Yes                 |

        `/search` **only** supports these optional parameters.  
        Include a parameter *only* when the user explicitly asks for it.

        assignment_status   // "unassigned"  
        indexed_by          // "newest" | "oldest" | "latest" | "stalled" | "closed"  
        engagement_status   // "considering" | "doing"  
        card_ids            // ["C‑123", …]  
        assignee_ids        // ["kevin", …]  
        creator_id          // "alice"  
        collection_ids      // ["Marketing", …]   // mention specific collections only  
        tag_ids             // ["performance", …]  
        terms               // ["latency", …]     // keyword refinement  

        --------------------------------------------------------------------
        RULES

        1. View awareness  
           • When the view is **inside a card**, **never** add a `/search` command.  
           • When the view is **list of cards** and the question needs card data, start with *one* `/search` (filtered, no empty params) and follow with *one* `/insight` that repeats the user's query *verbatim*.  

        2. Command limits  
           • At most **one** `/search` and **one** `/insight` per response.  
           • Do **not** attach extra keys to `/assign`, `/close`, `/tag`, `/clear`, or `/insight`.  
           • Delete any `/search` object that has no parameters.  

        3. Choosing commands  
           • Prefer `/insight` over `/search` unless the user explicitly asks for filters.  
           • Use `/assign`, `/close`, `/tag`, or `/clear` when they match the user’s intent.  

        4. JSON formatting  
           • Output a JSON **array** like `[ { "command": "/assign", ... }, { ... } ]`.  
           • Every string value must be wrapped in double quotes.  
           • No extra text or preamble.

        --------------------------------------------------------------------
        EXAMPLES

        • View: **list of cards**  
          User: “summarize performance issues”  
          Output:
          [
            { "command": "/search", "terms": ["performance"] },
            { "command": "/insight summarize performance issues" }
          ]

        • View: **inside a card**  
          Same user request → no search:  
          [
            { "command": "/insight summarize performance issues" }
          ]

        --------------------------------------------------------------------
        Generate the JSON array, obeying all rules above.
      PROMPT
    end

    def replace_names_with_ids(commands)
      commands.each do |command|
        if command["command"] == "/search"
          command["assignee_ids"] = command["assignee_ids"]&.filter_map { |name| assignee_from(name)&.id }
          command["creator_id"] = assignee_from(command["creator_id"])&.id if command["creator_id"]
          command["collection_ids"] = command["collection_ids"]&.filter_map { |name| Collection.where("lower(name) = ?", name.downcase).first&.id }
          command["tag_ids"] = command["tag_ids"]&.filter_map { |name| ::Tag.find_by_title(name)&.id }
          command.compact!
        end
      end
    end

    def assignee_from(string)
      string_without_at = string.delete_prefix("@")
      User.all.find { |user| user.mentionable_handles.include?(string_without_at) }
    end

    def build_chat_response_with(generated_commands)
      Command::Result::ChatResponse.new \
        command_lines: response_command_lines_from(generated_commands),
        context_url: response_context_url_from(generated_commands)
    end

    def response_command_lines_from(generated_commands)
      # We translate standalone /search commands as redirections to execute. Otherwise, they
      # will be excluded out from the commands to run, as they represent the context url.
      #
      # TODO: Tidy up this.
      if generated_commands.size == 1 && generated_commands.find { it["command"] == "/search" }
        [ "/visit #{cards_path(**generated_commands.first.without("command"))}" ]
      else
        generated_commands.filter { it["command"] != "/search" }.collect { it["command"] }
      end
    end

    def response_context_url_from(generated_commands)
      if generated_commands.size > 1 && search_command = generated_commands.find { it["command"] == "/search" }
        cards_path(**search_command.without("command"))
      end
    end
end
