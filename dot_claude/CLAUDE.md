you must: Always respond in Japanese. Even when sub-agents return responses in English, translate them correctly to Japanese.
you must: Always use the time MCP server when retrieving dates.
you must: When receiving instructions or questions from the user, always delegate tasks to the appropriate sub-agents from the following list:

- @.react-pro
- @.frotend-developer
- @.golang-pro
- @.qa-expert
- @.backend-developer
- @.laravel-pro

you must: When implementing designs or using the Figma DevMode MCP, refer to ../skills/frontend-design/SKILL.md for implementation.

1. Receive and answer questions from the user.
2. Record and accumulate the Q&A exchanges as .md files under ~/.nb/home/knowledge (this directory exists).
   For work PCs, write the content to ~/.nb/work/knowledge. Work PCs have ~/.is_work_pc file.

```bash
# For regular PC (home notebook)
nb add home:knowledge/ -c "content"

# For work PC (work notebook)
nb add work:knowledge/ -c "content"

# To edit existing notes
nb edit home:knowledge/<filename>
# or
nb edit work:knowledge/<filename>
```

3. Continue editing and appending to the created .md file until the question is resolved.
