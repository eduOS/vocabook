if !has("python") || exists("g:vocabook_pyloaded")
  finish
endif

python <<EOF
import vim 
import re
import MySQLdb as mdb
import argparse
import copy
from nltk.corpus import wordnet as wn

SHOW_SAVED_MODE = '# Entry Saved'
ALERTS = 'WARNING'
GUIDE_1_1 = "Guide: enter to choose"
GUIDE_2_1 = "Guide: press :w to save or update to database; press d for detail provided by nltk; press q to exit and save if modified"
UNLUCKY = '**I feel unlucky.**'

WORDBOOK = {
        'word' : '', 
        'definition' : '',
        'tags' : [],
        'excerpts' : '',
        'sentences' : '',
        }

def connectDB():
    try:
        con = mdb.connect('localhost','root',"104064", 'Vocabook')
    except:
        con = mdb.connect('localhost','root',"104064")
        initDB(con.cursor())
        con.commit()
    finally:
        con = mdb.connect('localhost','root',"104064", 'Vocabook')
        vim.command("let g:db_loaded = 1")
    return con

def initDB(cur):
    if not cur.execute("show databases like 'Vocabook'"):
        cur.execute("CREATE DATABASE Vocabook")

    cur.execute('use Vocabook')

    if not cur.execute("show tables like 'notebook'"):
        cur.execute("""CREATE TABLE notebook(
                    id INT(4) NOT NULL AUTO_INCREMENT PRIMARY KEY, \
                    word VARCHAR(100) NOT NULL, \
                    excerpts TEXT, \
                    sentences TEXT) ENGINE=InnoDB""")

    if not cur.execute("show tables like 'tags'"):
        cur.execute("""CREATE TABLE tags( \
                    id INT(4) NOT NULL AUTO_INCREMENT PRIMARY KEY, \
                    word VARCHAR(50), \
                    tag VARCHAR(80)) ENGINE=InnoDB""")
    cur.close()

def closeDB(con):
    con.close()
    vim.command("let g:db_loaded = 0")

def bwrite(s):
    b = vim.current.buffer
    # Never write more than two blank lines in a row
    if not s.strip() and not b[-1].strip() and not b[-2].strip():
        return

    if not b[0]:
        b[0] = s
    else:
        b.append(s)

def dump_to_Git(text):
    "this is the core function"
    # TODO: if the entry is a passage, then dump it to Git as a repo

def dump_to_DB(wb):
    con = connectDB()
    cur = con.cursor()
    # for the normal
    rst = cur.execute(('select * from notebook where word = %s'), (wb['word'],))
    if rst:
        sql = "UPDATE notebook SET excerpts=%s, sentences=%s WHERE word=%s"
        cur.execute(sql,(wb['excerpts'], wb['sentences'], wb['word']))
        sql = "DELETE FROM tags WHERE word=%s"
        cur.execute(sql,(wb['word']))
    else:
        sql = "INSERT INTO notebook (word, excerpts, sentences) VALUES(%s,%s,%s)"
        cur.execute(sql,(wb['word'], wb['excerpts'], wb['sentences']))
    sql = "INSERT INTO tags (word,tag) VALUES(%s,%s)"
    for tag in wb['tags']:
        cur.execute(sql,(wb['word'],tag))
    con.commit()
    bwrite(" ")
    bwrite(SHOW_SAVED_MODE)
    vim.command("normal G")
    vim.command("setlocal nomodified")
    cur.close()
    closeDB(con)

def extract_detailed_entry():
    """
    crawl detailed entry from the screen
    """
    wordbook = copy.copy(WORDBOOK)

    for line in vim.current.buffer:
        if (SHOW_SAVED_MODE in line or
            re.match("^#", line) or
            GUIDE_1_1 in line or GUIDE_2_1 in line):
            continue
        word = line.split("Word:")
        if len(word) > 1:
            wordbook['word'] = word[1].strip()
            continue
        tags = line.split("Tags:")
        if len(tags) > 1:
            wordbook['tags'] = tags[1].strip().split(', ')
            # remove empty entries
            wordbook['tags'] = filter(bool, wordbook['tags'])
            continue
        excerpts = line.split('Excerpts:')
        if len(excerpts) > 1:
            wordbook['excerpts'] = excerpts[1].strip()
            continue
        sentences = line.split('Sentences:')
        if len(sentences) > 1:
            wordbook['sentences'] = sentences[1].strip()
            continue
    vim.command("setlocal nomodified")
    return wordbook

def draw_detailed_entry(wb, buf=None):
    """
    only draw results from db
    recieve wordbook dictionary
    draw it with decorations on buffer
    """
    bwrite("Word: " + wb['word'])
    bwrite("Definition: " + wb['definition'])
    bwrite("Tags: " + str(wb['tags'] or ' '))
    bwrite("Excerpts: " + wb['excerpts'])
    bwrite("Sentences: " + wb['sentences'])
    bwrite(" ")
    vim.command("normal 2jA")
    vim.command("startinsert")
    
def load_detailed_dbentry(word):
    """
    load detailed entry from database
    receive a wordbook dictionary
    adjust the dictionary
    return a wordbook dictionary
    """
    wordbook = copy.copy(WORDBOOK)
    wordbook['word'] = word

    con = connectDB()
    cur = con.cursor()
    sql = 'select excerpts, sentences from notebook where word=%s'
    cur.execute(sql,(wordbook['word']))
    word_row = cur.fetchall()
    if len(word_row)==1:
        sql = 'select tag from tags where word = %s'
        cur.execute(sql,(wordbook['word']))
        tag_row = cur.fetchall()
        if len(tag_row)>0:
            list_tags = [tag[0] for tag in tag_row]
            wordbook['tags'] = ", ".join(list_tags)
        wordbook['excerpts'] = word_row[0][0] 
        wordbook['sentences'] = word_row[0][1]
        cur.close()
        closeDB(con)
        return wordbook
    elif len(word_row)==0: 
        cur.close()
        closeDB(con)
        return False
    cur.close()
    closeDB(con)

def load_from_wordnet(wd):
    'for details as comments'
    # TODO call a function to show details, including trigering for hyponymy and hypernym etc.
    bwrite(' ')
    bwrite('# load from wordnet')
    bwrite('# Hyponyms: ' + ', '.join([str(word.name()) for word in wn.synset(wd).hyponyms()]))
    bwrite('# Hypernyms: ' + ', '.join([str(word.name()) for word in wn.synset(wd).hypernyms()]))
    bwrite('# Lemmas: ' + ', '.join([str(lemma.name()) for lemma in wn.synset(wd).lemmas()]))
    bwrite('# Examples: ' + ', '.join([str(word) for word in wn.synset(wd).examples()]))
    vim.command("normal G")
    vim.command("setlocal nomodified")

def extract_dump():
    dump_to_DB(extract_detailed_entry())

def init_detailed_entry():
    """
    clear all entries except the one under the cursor
    """
    wordbook = copy.copy(WORDBOOK)
    vim.command("setlocal modifiable")
    cur_line = vim.eval("getline(\".\")")
    vim.command('normal! ggdG')
    vim.command("let t:win_level = 2")
    #vim.command("autocmd BufWriteCmd _vnb_ :python extract_dump()")

    # get word and definition from the list line
    wordbook['word'] = cur_line.split()[1].replace("'",'')
    defi = wordbook['definition'] = ' '.join(cur_line.split()[2:]).split(' (')[0]
    # get tags, excerpts and sentences from db if dumped
    dwordbook = load_detailed_dbentry(wordbook['word'])
    # get excerpt from text
    lc_excer = ' '.join(re.sub(r'[\*_\[\]]','',re.sub(r'\[\d\]','',re.sub(r'\]\(.*\)','',vim.eval("t:cssentence")))).split())
    if dwordbook:
        wordbook = dwordbook
        wordbook['definition'] = defi
        #db_excer = wordbook['excerpts']
        # this should be removed if all excerpts in db are modified
        db_excer = ' '.join(re.sub(r'[\*_\[\]]','',re.sub(r'\[\d\]','',re.sub(r'\]\(.*\)','',wordbook['excerpts']))).split())
#        sdiff = difflib.SequenceMatcher(None, lc_sen, db_sen).ratio()
        if lc_excer in db_excer:
            wordbook['excerpts'] = db_excer
        else:
            wordbook['excerpts'] = db_excer + ' ' + lc_excer
    else:
        wordbook['excerpts'] = lc_excer
    draw_detailed_entry(wordbook)
    target_word = wordbook['word']
    vim.command(""":execute 'nnoremap <buffer> <leader>d :python load_from_wordnet("%s")<CR>'"""% target_word)
    bwrite(GUIDE_2_1)
    vim.command("let t:win_level = 2")
    vim.command("setlocal nomodified")

def input_manually():
    'if the system misses the entry then input it manually into db and nltk'
    pass

def complete_while_writing():
    """while writing vocabook can automatically
    remind the writer words and sentences according 
    to nltk and the meaning of the current 
    sentence being writing. Information is shown 
    in popup menu and preview window"""
    pass

def draw_entry_synsets(wd):
    """
    Show entries according to the results from wordnet
    with number of excerpts and tags if any from requrying the database
    Maybe need fold features
    """

    vim.command("setlocal modifiable")
    for i,j in enumerate(wn.synsets(wd)):
        w_name = str(j.name())
        wordbook = copy.copy(WORDBOOK)
        wordbook['word'] = w_name
        dwordbook = load_detailed_dbentry(wordbook['word'])
        if dwordbook:
            wordbook = dwordbook
            sentLen = ' (' + str(sum(1 for ch in wordbook['excerpts'] if ch in '!.?')) + ')'
            tags = ' [' + str(wordbook['tags']) + ']'
            bwrite(str(i) + ". " + w_name + " " + str(j.definition()) + sentLen + tags)
        else:
            bwrite(str(i) + ". " + w_name + " " + str(j.definition()))
    bwrite(UNLUCKY+'  '+wd)
    bwrite(GUIDE_1_1)
    #vim.command(""":execute 'nnoremap <buffer> <CR> :python show_the_entry()<CR>'""")
    # TODO multientry dump and multitimes dump using visual choosing to choose
    # TODO show how many excerpts have been dumped with a number appending the line
    vim.command("setlocal nomodified")
    vim.command("setlocal nomodifiable")
    vim.command("let t:win_level = 1")

def pyvocaMain():
    wd = vim.eval('t:csword')
    wd = wd.replace("'",'')
    draw_entry_synsets(wd)

def draw_search_list(wdlst,msg=None):
    bwrite(msg)
    for i,j in enumerate(wdlst):
        bwrite(str(i)+'. '+j)
    bwrite('  ')

def search_by_tag(tag):
    """
    look up words tagged 
    return word in the same format as list
    supper search should be extended: synonym
    """
    con = connectDB()
    cur = con.cursor()
    sql = 'select distinct word from tags where tag like %s'
    cur.execute(sql,('%' + tag + '%',))
    word_row = cur.fetchall()
    if not word_row:
        cur.close()
        closeDB(con)
        return None
    cur.close()
    closeDB(con)
    return [word[0] for word in word_row]

def search_by_sentence(word):
    '''
    recieve any word
    return the word which can be detailed
    search by excerpts and sentences in 
    database
    '''
    con = connectDB()
    cur = con.cursor()
    sql = 'select distinct word from notebook where excerpts like %s or sentences like %s'
    cur.execute(sql,('%' + word + '%','%' + word + '%'))
    word_row = cur.fetchall()
    if not word_row:
        cur.close()
        closeDB(con)
        return None
    cur.close()
    closeDB(con)
    return [word[0] for word in word_row]

def pyvocaSearch(word):
    '''
    search word from db and list items
    press enter for showing details 
    in _vnb_ window. list window doesn't disappear
    if the word == 0 search the whole vocabulary
    else seach the words relating to that one
    '''
    wordlist = [w for w in search_by_tag(word)]
    msg = 'Results from tag searching'
    draw_search_list(wordlist,msg)
    wordlist = [w for w in search_by_sentence(word)]
    msg = 'Results from sentence searching'
    draw_search_list(wordlist,msg)
    

EOF

function! pyvocabook#initvcbw()
    let g:vocabook_pyloaded = 1
    let t:csword = shellescape(expand("<cword>"))
    normal *``
    normal! ("ayasn
    let t:cssentence =substitute(@a,'\n',' ','g')
    windo if expand("%")=="_vnb_" |q!|endif
    15sp _vnb_
    setlocal bufhidden=delete noswapfile
    nnoremap <buffer> <silent> q :q!<CR>
    let t:win_level = 1
    nnoremap <buffer> <CR> :call <SID>showTheEntry()<CR>
    python pyvocaMain()
endfunction

function! pyvocabook#vocSearch(word)
    windo if expand("%")=="_vnbl_" |q!|endif
    25vsp _vnbl_
    setlocal bufhidden=delete noswapfile
    nnoremap <buffer> <silent> q :q!<CR>
    python pyvocaSearch(a:word)
endfunction

function! s:saveEntry()
    normal gg
    let matchnum0 = search('\v^Word:', 'c', line("w$"))  
    if matchnum0 > 0
        python extract_dump()
    endif
endfunction

function! s:showTheEntry()
    normal 0
    let matchnum1 = search('\v^\d{1,2}\. [a-z]*\.\w\.\d{1,3}', 'c', line("w$"))  
    if matchnum1 > 0
        python init_detailed_entry()
    endif
endfunction

function! s:bufDelete()
    let t:win_level = 0
endfunction

autocmd BufWriteCmd _vnb_ call s:saveEntry()
autocmd BufDelete _vnb_ call s:bufDelete()

