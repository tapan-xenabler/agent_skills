require 'json'

files = [
  { id: "executive", title: "Executive Summary", name: "Executive-Code-Review.md" },
  { id: "inventory", title: "Inventory & Build", name: "Project-Inventory-and-Build-Verification.md" },
  { id: "architecture", title: "Architecture", name: "Architecture-and-Modernization-Review.md" },
  { id: "security", title: "Security & Privacy", name: "Security-and-Privacy-Review.md" },
  { id: "performance", title: "Performance", name: "Performance-Memory-and-Battery-Review.md" },
  { id: "ui", title: "UI & Accessibility", name: "UI-UX-Design-System-and-Accessibility-Review.md" },
  { id: "testing", title: "Testing Strategy", name: "Testing-Strategy.md" },
  { id: "release", title: "Release Readiness", name: "Release-Readiness-Review.md" },
  { id: "roadmap", title: "Roadmap", name: "Remediation-Roadmap.md" },
  { id: "findings", title: "Detailed Findings", name: "Detailed-Findings.md" },
  { id: "severity", title: "Severity Summary", name: "Severity-Summary.md" },
  { id: "risk", title: "Risk Summary", name: "Module-File-Risk-Summary.md" },
  { id: "blockers", title: "Release Blockers", name: "Release-Blocker-Checklist.md" },
  { id: "unknowns", title: "Unknowns & Blockers", name: "Unknowns-and-Validation-Blockers.md" },
  { id: "pr", title: "PR Checklist", name: "Pull-Request-Checklist.md" }
]

def markdown_to_html(text)
  code_blocks = []
  
  # 1. Extract code blocks safely
  text.gsub!(/```[a-z]*\n(.*?)```/m) do |m|
    code_blocks << "<pre><code>#{m.gsub(/```[a-z]*\n/, '').gsub('```', '').gsub('<', '&lt;').gsub('>', '&gt;')}</code></pre>"
    "___CODE_BLOCK_#{code_blocks.length - 1}___"
  end

  # 2. Escape all remaining < and > in the text so things like <style> don't break the HTML!
  text.gsub!('<', '&lt;')
  text.gsub!('>', '&gt;')

  in_table = false
  table_rows = []
  in_list = false
  list_type = ""
  parsed_lines = []
  
  text.each_line do |line|
    line = line.chomp
    next if line.strip == "---" && in_table 
    next if line.strip =~ /^\|?[-|: ]+\|?$/ && in_table 
    
    if line.strip.start_with?('|') && line.strip.end_with?('|')
      in_table = true
      cells = line.strip.split('|')[1..-2].map(&:strip)
      table_rows << "<tr>" + cells.map { |c| "<td>#{c}</td>" }.join + "</tr>"
      next
    else
      if in_table
        if table_rows.any?
          table_rows[0].gsub!('<td>', '<th>')
          table_rows[0].gsub!('</td>', '</th>')
          parsed_lines << "<div class='table-container'><table>#{table_rows.join}</table></div>"
        end
        in_table = false
        table_rows = []
      end
    end

    match_ul = line.match(/^\s*-\s+(.*)$/)
    match_ol = line.match(/^\s*\d+\.\s+(.*)$/)
    
    if match_ul || match_ol
      content = match_ul ? match_ul[1] : match_ol[1]
      new_list_type = match_ul ? "ul" : "ol"
      
      if !in_list || list_type != new_list_type
        if in_list
            parsed_lines << "</#{list_type}>"
        end
        in_list = true
        list_type = new_list_type
        parsed_lines << "<#{list_type}>"
      end
      
      if content.start_with?("[ ] ")
        parsed_lines << "<li class='task-list-item'><input type='checkbox' disabled class='md3-checkbox'> #{content[4..-1]}</li>"
      elsif content.start_with?("[x] ") || content.start_with?("[X] ")
        parsed_lines << "<li class='task-list-item'><input type='checkbox' checked disabled class='md3-checkbox'> #{content[4..-1]}</li>"
      else
        parsed_lines << "<li>#{content}</li>"
      end
      next
    else
      if in_list && line.strip.empty?
      elsif in_list
        parsed_lines << "</#{list_type}>"
        in_list = false
      end
    end

    if line =~ /^### (.*?)$/
      parsed_lines << "<h3>#{$1}</h3>"
    elsif line =~ /^## (.*?)$/
      parsed_lines << "<h2>#{$1}</h2>"
    elsif line =~ /^# (.*?)$/
      parsed_lines << "<h1>#{$1}</h1>"
    elsif line.strip.empty?
      parsed_lines << "<br>"
    else
      parsed_lines << "<p>#{line}</p>"
    end
  end
  
  if in_table && table_rows.any?
    table_rows[0].gsub!('<td>', '<th>')
    table_rows[0].gsub!('</td>', '</th>')
    parsed_lines << "<div class='table-container'><table>#{table_rows.join}</table></div>"
  end
  if in_list
    parsed_lines << "</#{list_type}>"
  end

  html_out = parsed_lines.join("\n")
  html_out.gsub!(/\*\*(.*?)\*\*/, '<strong>\1</strong>')
  html_out.gsub!(/\*(.*?)\*/, '<em>\1</em>')
  html_out.gsub!(/`(.*?)`/, '<code class="inline-code">\1</code>')
  
  # Severity Badges Injection
  html_out.gsub!(/<strong>(Critical)<\/strong>/i, '<span class="badge badge-critical">Critical</span>')
  html_out.gsub!(/<strong>(High)<\/strong>/i, '<span class="badge badge-high">High</span>')
  html_out.gsub!(/<strong>(Medium)<\/strong>/i, '<span class="badge badge-medium">Medium</span>')
  html_out.gsub!(/<strong>(Low)<\/strong>/i, '<span class="badge badge-low">Low</span>')
  html_out.gsub!(/<strong>(Failed)<\/strong>/i, '<span class="badge badge-critical">Failed</span>')
  html_out.gsub!(/<strong>(Passed)<\/strong>/i, '<span class="badge badge-passed">Passed</span>')
  html_out.gsub!(/<strong>(Warning)<\/strong>/i, '<span class="badge badge-warning">Warning</span>')
  
  code_blocks.each_with_index do |block, i|
    html_out.gsub!("___CODE_BLOCK_#{i}___", block)
  end
  
  html_out.gsub!("<br>\n<br>", "<br>")
  html_out.gsub!(/<\/h1>\s*<br>/, "</h1>")
  html_out.gsub!(/<\/h2>\s*<br>/, "</h2>")
  html_out.gsub!(/<\/h3>\s*<br>/, "</h3>")
  html_out.gsub!(/<\/div>\s*<br>/, "</div>")
  
  html_out
end

nav_links = ""
main_content = ""

files.each_with_index do |file, index|
  path = File.join("code audit", file[:name])
  if File.exist?(path)
    content = File.read(path)
    parsed_content = markdown_to_html(content)
    nav_links += "<li><a href='##{file[:id]}' class='nav-item'>#{index + 1}. #{file[:title]}</a></li>\n"
    main_content += "<section id='#{file[:id]}' class='section-card'>\n#{parsed_content}\n</section>\n"
  end
end

final_html = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Xenabler Code Audit</title>
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        :root {
            /* Material 3 Light Theme Colors */
            --md-sys-color-background: #F9F8F5;
            --md-sys-color-on-background: #191C1A;
            --md-sys-color-surface: #FFFFFF;
            --md-sys-color-surface-container-low: #FDFDFD;
            --md-sys-color-surface-container: #F6F6F6;
            --md-sys-color-on-surface: #191C1A;
            --md-sys-color-on-surface-variant: #414942;
            --md-sys-color-outline: #717971;
            
            --md-sys-color-primary: #6438F4;
            --md-sys-color-on-primary: #00391B;
            --md-sys-color-primary-container: #6438F4;
            --md-sys-color-on-primary-container: #FFFFFF;

            --md-sys-color-secondary-container: #EFEBFF;
            --md-sys-color-on-secondary-container: #6438F4;
            
            --md-sys-color-error: #BA1A1A;
            --md-sys-color-warning: #B36B00;
        }

        /* PURE CSS DARK MODE HACK */
        #theme-switch:checked ~ .app-container {
            --md-sys-color-background: #0F1825;
            --md-sys-color-on-background: #E1E3DF;
            --md-sys-color-surface: #101826;
            --md-sys-color-surface-container-low: #141D2B;
            --md-sys-color-surface-container: #1A2436;
            --md-sys-color-on-surface: #E1E3DF;
            --md-sys-color-on-surface-variant: #C0C9C1;
            --md-sys-color-outline: #8B938A;
            
            --md-sys-color-primary: #6438F4;
            --md-sys-color-on-primary: #00391B;
            --md-sys-color-primary-container: #6438F4;
            --md-sys-color-on-primary-container: #FFFFFF;

            --md-sys-color-secondary-container: #281D4B;
            --md-sys-color-on-secondary-container: #DD68FF;

            --md-sys-color-error: #FFB4AB;
            --md-sys-color-warning: #FFB02E;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        
        body {
            font-family: 'Roboto', sans-serif;
            background-color: var(--md-sys-color-background);
            margin: 0;
            padding: 0;
        }

        .app-container {
            background-color: var(--md-sys-color-background);
            color: var(--md-sys-color-on-background);
            line-height: 1.6;
            transition: background-color 0.3s, color 0.3s;
            display: flex;
            min-height: 100vh;
        }

        /* Sidebar */
        .sidebar {
            width: 320px;
            background-color: var(--md-sys-color-surface-container-low);
            position: fixed;
            top: 0;
            left: 0;
            height: 100vh;
            overflow-y: auto;
            padding: 1.5rem 1rem;
            display: flex;
            flex-direction: column;
            border-right: 1px solid var(--md-sys-color-outline);
            z-index: 100;
            transition: background-color 0.3s;
        }

        .sidebar h2 {
            color: var(--md-sys-color-on-surface);
            font-size: 1.25rem;
            margin-bottom: 2rem;
            padding: 0 1rem;
            font-weight: 500;
        }

        .sidebar ul { list-style: none; flex-grow: 1; }
        .sidebar li { margin-bottom: 0.2rem; display: block; }
        
        .sidebar a {
            color: var(--md-sys-color-on-surface-variant);
            text-decoration: none;
            display: block;
            padding: 0.8rem 1rem;
            border-radius: 100px; 
            font-size: 0.875rem;
            font-weight: 500;
            transition: all 0.2s ease;
        }

        .sidebar a:hover {
            background-color: var(--md-sys-color-surface-container);
        }

        .sidebar a.active {
            color: var(--md-sys-color-on-secondary-container);
            background-color: var(--md-sys-color-secondary-container);
        }

        /* Pure CSS Toggle Button */
        .theme-toggle-label {
            margin-top: 2rem;
            background-color: var(--md-sys-color-primary-container);
            color: var(--md-sys-color-on-primary-container);
            padding: 1rem 1.5rem;
            border-radius: 16px;
            text-align: center;
            cursor: pointer;
            font-size: 0.875rem;
            font-weight: 500;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            box-shadow: 0 4px 8px 3px rgba(0,0,0,0.15);
            user-select: none;
        }

        .theme-toggle-label:hover { 
            box-shadow: 0 6px 12px 4px rgba(0,0,0,0.15);
        }

        /* Main Content */
        .main-content {
            margin-left: 320px;
            padding: 2.5rem 4rem;
            width: calc(100% - 320px);
            max-width: 1300px;
        }

        /* Dash Grid */
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1.5rem;
            margin-bottom: 3rem;
        }

        .stat-card {
            background-color: var(--md-sys-color-surface-container);
            border-radius: 16px;
            padding: 1.5rem;
            box-shadow: 0 1px 3px 1px rgba(0,0,0,0.15);
            transition: background-color 0.3s;
        }

        .stat-title {
            font-size: 0.875rem;
            font-weight: 500;
            color: var(--md-sys-color-on-surface-variant);
            margin-bottom: 0.5rem;
        }

        .stat-value {
            font-size: 2.25rem;
            font-weight: 400;
            color: var(--md-sys-color-on-surface);
            margin-bottom: 0.25rem;
            line-height: 1.2;
        }

        .stat-value.warning { color: var(--md-sys-color-warning); }
        .stat-value.danger { color: var(--md-sys-color-error); }
        .stat-value.success { color: var(--md-sys-color-primary); }

        .stat-desc {
            font-size: 0.875rem;
            font-weight: 400;
            color: var(--md-sys-color-on-surface);
        }

        .section-card {
            background-color: var(--md-sys-color-surface-container-low);
            border-radius: 16px;
            padding: 2.5rem;
            margin-bottom: 2.5rem;
            box-shadow: 0 2px 6px 2px rgba(0,0,0,0.15);
            transition: background-color 0.3s;
        }

        .section-card h1 {
            font-size: 2rem;
            font-weight: 400;
            margin-bottom: 1.5rem;
            color: var(--md-sys-color-on-surface);
            border-bottom: 1px solid var(--md-sys-color-outline);
            padding-bottom: 1rem;
        }

        h2 { font-size: 1.375rem; font-weight: 500; margin: 2rem 0 1rem; color: var(--md-sys-color-on-surface); }
        h3 { font-size: 1.125rem; font-weight: 500; margin: 1.5rem 0 0.75rem; color: var(--md-sys-color-on-surface); }
        p { margin-bottom: 1rem; font-size: 1rem; font-weight: 400; }
        ul, ol { padding-left: 2rem; margin-bottom: 1.5rem; }
        li { margin-bottom: 0.5rem; display: list-item; }

        /* Beautiful Code Chips */
        code.inline-code {
            background-color: #E8DEF8; /* Soft violet/grey tint */
            color: #1D192B; /* Dark text for contrast */
            padding: 0.2em 0.5em;
            border-radius: 6px;
            font-family: 'Roboto Mono', 'Courier New', monospace;
            font-size: 0.85em;
            font-weight: 500;
            border: none;
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        
        #theme-switch:checked ~ .app-container code.inline-code {
            background-color: #4A4458;
            color: #E8DEF8;
        }
        
        pre {
            background-color: #1A1C1E;
            color: #E1E3DF;
            padding: 1.25rem;
            border-radius: 16px;
            overflow-x: auto;
            margin: 1.5rem 0;
            border: 1px solid var(--md-sys-color-outline);
        }
        pre code {
            background: transparent;
            color: inherit;
            padding: 0;
            border: none;
            box-shadow: none;
            font-family: 'Roboto Mono', monospace;
        }

        /* Severity Badges */
        .badge {
            padding: 2px 8px;
            border-radius: 6px;
            font-size: 0.85em;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            display: inline-block;
        }
        
        /* Fixed colors to pop in both light and dark modes */
        .badge-critical { background-color: #FFB4AB; color: #690005; }
        .badge-high { background-color: #FFDAD6; color: #410002; }
        .badge-medium { background-color: #FFDF9E; color: #3E2E04; }
        .badge-low { background-color: #DCE5DB; color: #151D18; }
        .badge-passed { background-color: #76F9A2; color: #00391B; }
        .badge-warning { background-color: #FFDF9E; color: #3E2E04; }

        /* Tables */
        .table-container {
            width: 100%;
            overflow-x: auto;
            margin: 1.5rem 0;
            border-radius: 12px;
            border: 1px solid var(--md-sys-color-outline);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            background-color: var(--md-sys-color-surface);
            transition: background-color 0.3s;
        }
        th, td {
            padding: 1rem;
            border-bottom: 1px solid var(--md-sys-color-outline);
            vertical-align: top;
        }
        th {
            background-color: var(--md-sys-color-surface-container);
            font-weight: 500;
            color: var(--md-sys-color-on-surface);
            font-size: 0.875rem;
        }
        tr:last-child td { border-bottom: none; }

        /* Custom Checkbox */
        .task-list-item { 
            list-style-type: none; 
            display: flex; 
            align-items: flex-start; 
            margin-left: -2rem;
        }
        .md3-checkbox { 
            margin-top: 0.35rem; 
            margin-right: 0.75rem; 
            accent-color: var(--md-sys-color-primary); 
            width: 18px;
            height: 18px;
        }

        @media (max-width: 1024px) {
            .sidebar { width: 260px; }
            .main-content { margin-left: 260px; padding: 2rem; width: calc(100% - 260px); }
        }
        @media (max-width: 768px) {
            .app-container { flex-direction: column; }
            .sidebar { width: 100%; height: auto; position: relative; padding: 1.5rem; border-right: none; border-bottom: 1px solid var(--md-sys-color-outline); }
            .main-content { margin-left: 0; padding: 1.5rem; width: 100%; }
        }
    </style>
</head>
<body>

    <!-- PURE CSS THEME TOGGLE CHECKBOX -->
    <input type="checkbox" id="theme-switch" style="display: none;">

    <div class="app-container">
        <nav class="sidebar">
            <h2>Xenabler Audit</h2>
            <ul id="nav-links">
#{nav_links}
            </ul>
            <label for="theme-switch" class="theme-toggle-label">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
                Toggle Theme
            </label>
        </nav>

        <main class="main-content" id="content-container">
            
            <div class="dashboard-grid">
                <div class="stat-card">
                    <div class="stat-title">Overall Score</div>
                    <div class="stat-value warning">55 <span style="font-size:1.5rem; color:var(--md-sys-color-on-surface-variant);">/ 100</span></div>
                    <div class="stat-desc">Needs Improvement</div>
                </div>
                <div class="stat-card">
                    <div class="stat-title">Project Readiness</div>
                    <div class="stat-value danger">Not Ready</div>
                    <div class="stat-desc">Critical Blockers Present</div>
                </div>
                <div class="stat-card">
                    <div class="stat-title">Tech Stack</div>
                    <div class="stat-value" style="font-size:1.7rem;">Kotlin 2.3.10</div>
                    <div class="stat-desc">Target SDK 36 • MVVM • AGP 9.0</div>
                </div>
            </div>

#{main_content}
        </main>
    </div>

    <!-- Scroll Highlighting Only -->
    <script>
        const observerOptions = { root: null, rootMargin: '-10% 0px -80% 0px', threshold: 0 };
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const id = entry.target.getAttribute('id');
                    document.querySelectorAll('.nav-item').forEach(link => {
                        link.classList.remove('active');
                        if (link.getAttribute('href') === `#${id}`) {
                            link.classList.add('active');
                        }
                    });
                }
            });
        }, observerOptions);

        document.querySelectorAll('section').forEach(section => observer.observe(section));

        document.querySelectorAll('.nav-item').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                document.querySelector(this.getAttribute('href')).scrollIntoView({ behavior: 'smooth' });
            });
        });
    </script>
</body>
</html>
HTML

File.write("code audit/code_audit_report.html", final_html)
puts "Material 3 HTML generated securely to code_audit_report.html."
