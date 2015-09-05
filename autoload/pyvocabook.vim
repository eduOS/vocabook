if !has("python") || exists("g:vocabook_pyloaded")
  finish
endif

python <<EOF
import vim 
import re
import MySQLdb as mdb
import argparse
from nltk.corpus import wordnet as wn

SHOW_SAVED_MODE = '# Entry Saved'
ALERTS = 'WARNING'
GUIDE_1_1 = "Guide: enter to choose"
GUIDE_2_1 = "Guide: press :w to save or update to database; press d for detail provided by nltk; press q to exit and save if modified"
UNLUCKY = '**I feel unlucky.**'

def connectDB():
    if vim.eval("g:db_loaded") == "0":
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

def dump_to_Git():
    "this is the core function"
    # TODO: if the entry is a passage, then dump it to Git as a repo

def dump_to_DB(wb):
    con = connectDB()
    cur = con.cursor()
    # for the normal
    if vim.eval("g:word_is_in_db") == "1":
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
    vim.command("let g:word_is_in_db = 1")
    bwrite(" ")
    bwrite(SHOW_SAVED_MODE)
    vim.command("normal G")
    vim.command("setlocal nomodified")
    cur.close()
    closeDB(con)

def extract_entry():
    " extract the sentence where the cursor is in"
    wordbook = {
            'word' : '', # word in wordnet, produced by nltk
            'definition' : '',
            'tags' : [],
            'excerpts' : '',
            'sentences' : '',
            }
    for line in vim.current.buffer:
        if SHOW_SAVED_MODE in line or re.match("^#", line) or GUIDE_1_1 in line or GUIDE_2_1 in line:
            continue
        word = line.split("Word:")
        if len(word) > 1:
            wordbook['word'] = word[1].strip()
            continue
        tags = line.split("Tags:")
        if len(tags) > 1:
            wordbook['tags'] = tags[1].lstrip().split(', ')
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

def load_from_db(wd, df):
    con = connectDB()
    cur = con.cursor()
    bwrite("Word: "+wd)
    bwrite("Definition: "+df)
    sql = 'select excerpts, sentences from notebook where word=%s'
    cur.execute(sql,(wd))
    word_row = cur.fetchall()
    if len(word_row)==1:
        vim.command("let g:word_is_in_db = 1")
        sql = 'select tag from tags where word = %s'
        cur.execute(sql,(wd))
        tag_row = cur.fetchall()
        if len(tag_row)>0:
            list_tags = [tag[0] for tag in tag_row]
            tags = ", ".join(list_tags)
            bwrite("Tags: "+tags)
        db_sen = word_row[0][0] 
        lc_sen = vim.eval("t:cssentence").strip()
#        sdiff = difflib.SequenceMatcher(None, lc_sen, db_sen).ratio()
        if lc_sen in db_sen:
            excerpt = db_sen
        else:
            excerpt = db_sen + ' ' + lc_sen
        bwrite("Excerpts: "+excerpt)
        bwrite("Sentences: "+word_row[0][1])
    elif len(word_row)==0: 
        bwrite("Tags: ")
        bwrite("Excerpts: "+vim.eval("t:cssentence"))
        bwrite("Sentences: ")
        bwrite(" ")
        bwrite("# No match from database. ")
        vim.command("let g:word_is_in_db = 0")
    vim.command("normal 2jA ")
    vim.command("startinsert")
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
    dump_to_DB(extract_entry())

def show_the_entry():
    "clear all entries except the one under the cursor"
    vim.command("setlocal modifiable")
    cur_line = vim.eval("getline(\".\")")
    vim.command('normal! ggdG')
    vim.command("let g:win_level = 2")
    #vim.command("autocmd BufWriteCmd _vnb_ :python extract_dump()")
    target_word = cur_line.split()[1].replace("'",'')
    definition = ' '.join(cur_line.split()[2:])
    load_from_db(target_word, definition)
    vim.command(""":execute 'nnoremap <buffer> <leader>d :python load_from_wordnet("%s")<CR>'"""% target_word)
    bwrite(GUIDE_2_1)
    vim.command("let g:win_level = 2")
    vim.command("setlocal nomodified")

def input_manually():
    'if the system misses the entry then input it manually into db and nltk'
    pass

def complete_while_writing():
    'while writing vocabook can automatically remind the writer words and sentences according to nltk and the meaning of the current sentence being writing. Information is shown in popup menu and preview window'
    pass

def show_entries(wd):
    for i,j in enumerate(wn.synsets(wd)):
        w_name = str(j.name())
        bwrite(str(i) + ". " + w_name + " " + str(j.definition()))
    bwrite(UNLUCKY+'  '+wd)
    bwrite(GUIDE_1_1)
    #vim.command(""":execute 'nnoremap <buffer> <CR> :python show_the_entry()<CR>'""")
    # TODO multientry dump and multitimes dump using visual choosing to choose
    # TODO show how many excerpts have been dumped with a number appending the line
    vim.command("setlocal nomodifiable")
    vim.command("let g:win_level = 1")

def pyvocaMain():
    wd = vim.eval('t:csword')
    wd = wd.replace("'",'')
    show_entries(wd)


EOF


function! pyvocabook#init()
    let g:vocabook_pyloaded = 1
    let t:csword = shellescape(expand("<cword>"))
    normal! ("ayas
    let t:cssentence =substitute(@a,'\n',' ','g')
    windo if expand("%")=="_vnb_" |q!|endif
    10sp _vnb_
    setlocal bufhidden=delete noswapfile
    nnoremap <buffer> <silent> q :q!<CR>
    let g:win_level = 1
    nnoremap <buffer> <CR> :call <SID>showTheEntry()<CR>
endfunction


function! s:saveEntry()
    if g:win_level == 2
        python extract_dump()
    endif
endfunction

function! s:showTheEntry()
    if g:win_level == 1
        python show_the_entry()
    endif
endfunction

function! s:bufLeave()
    let g:win_level = 0
endfunction

autocmd BufWriteCmd _vnb_ call s:saveEntry()
autocmd BufLeave _vnb_ call s:bufLeave()

