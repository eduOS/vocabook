import vim 
import MySQLdb as mdb
import argparse
from snake import *
from nltk.corpus import wordnet as wn

con = mdb.connect('localhost','root',"104064")
cur = con.cursor()

if not cur.execute("show databases like 'VocabNB'"):
    cur.execute("CREATE DATABASE VocabNB")
cur.execute("use VocabNB")

if not cur.execute("show tables like 'notebook'"):
    cur.execute("""CREATE TABLE notebook(
                id SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                word VARCHAR(100) NOT NULL,
                excerpts TEXT,
                sentences TEXT) ENGINE=InnoDB""")

if not cur.execute("show tables like 'tag'"):
    cur.execute("""CREATE TABLE tags(
                word_id SMALLINT,
                tag VARCHAR(800)) ENGINE=InnoDB""")

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
    # TODO: if the entry is a passage, then dump it to Git as a repo

def dump_to_MySQL(wd):
    " extract the sentence where the cursor is in"
    wordbook = {
            'word' : '', # word in wordnet, produced by nltk
            'definition' : '',
            'tags' : [],
            'excerpts' : '',
            'sentences' : '',
            }
    for line in vim.current.buffer:
        word = line.split("## Word:")
        if len(word) > 1:
            wordbook['word'] = word[1].strip()
            continue
        tags = line.split("## Tags:")
        if len(tags) > 1:
            wordbook['tags'] = tags[1].lstrip().split(', ')
            # remove empty entries
            wordbook['tags'] = filter(bool, wordbook['tags'])
            continue
        excerpts = line.split('## Excerpts:')
        if len(excerpts) > 1:
            wordbook['excerpts'] = excerpts[1].strip()
            continue

        if line == SHOW_SAVED_MODE or ALERTS in line:
            continue
        

    sql = "SELECT id FROM notebook WHERE word=%s"
    cur.execute(sql,(w_name))
    wd_id = cur.fetchone()

    if wd_id and (excerpts or sentences):
        sql = "UPDATE notebook SET excerpts=%s, sentences=%s"
        cur.execute(sql,(excerpts,sentences))
    else if not wd_id and (excerpts or sentences)
        sql = "insert into notebook values (%s,%s)"
        cur.execute(sql,(excerpts,sentences))

    # row in db and filled
    # row in db and unfilled
    # row not in db and filled
    # row not in db and unfilled

    if wd_id:
        sql = "DELETE FROM tag WHERE word_id=%s"
        cur.execute(sql,(wd_id))

    if tags:
        sql = "INSERT INTO tag (word_id,tags) VALUES(%s,%s)"
        for tag in tags:
            cur.execute(sql,(wd_id,tag))
    print excerpts,sentences,tags
    con.commit()
    vim.command("setlocal nomodified")

def load_from_db(wd, df):
    bwrite("Word: "+wd)
    bwrite("Definition: "+df)
    sql = 'select excerpts, sentences from notebook where word=' + wd
    cur.execute(sql)
    word_row = cur.fetchall()
    if len(word_row)==1:
        vim.command("let g:word_is_in_db = 1")
        sql = 'select tag from tags where word = ' + wd
        cur.execute(sql)
        tag_row = cur.fetchall()
        if len(tag_row)>0:
            tags = ", ".join(rows)
            bwrite("Tags: "+tags)
        bwrite("Excerpts: "+word_row[0]+)
        bwrite("Sentences: "+word_row[1])
    elif len(row)==0: 
        bwrite("# No match from database. Do it for yourself by entering t for Tags, s for sentences")
        vim.command("let g:word_is_in_db = 0")

def load_from_wordnet(wd):
    'for details as comments'

def show_the_entry():
    "clear all entries except the one under the cursor"
    vim.command('"eyyggdG')
    target_word = vim.eval("@e").split()[1]
    definition = vim.eval("@e").split()[2]
    load_from_db(target_word, definition)
    load_from_wordnet(target_word)

    vim.command("let g:win_level = 1")
    # TODO call a function to show details, including trigering for hyponymy and hypernym etc.
    print("press s to dump the entry to mysql")

def show_in_buffer(wd):
    vim.command('windo if expand("%")=="d-tmp" |q!|endif')
    vim.command("10sp d-tmp")
    vim.command("setlocal buftype=nofile bufhidden=delete noswapfile")
    bwrite('<---press p to paste the sentence containing the word to one of the excerpt; press c to clear all other entries--->\n')
    for i,j in enumerate(wn.synsets(wd)):
        w_name = str(j.name())
        bwrite(str(i) + ". " + w_name + " " + str(j.definition()))
        sql = """select tags from tag where word_id in (select id from notebook where word=%s)"""
        cur.execute(sql,(w_name))
            bwrite("Tags: "+tags)
        sql = """select excerpts from notebook where word=%s"""
        cur.execute(sql,(w_name))
        rows = cur.fetchall()
        bwrite("Excerpts: "+" ".join(rows))
        sql = """select sentences from notebook where word=%s"""
        cur.execute(sql,(w_name))
        rows = cur.fetchall()
        bwrite("Sentences: "+" ".join(rows))
        bwrite('\n')
    vim.command("normal gg")
    vim.command("let g:vocab_one_entry = 2")
    # delete all words except that one the cursor is in
    vim.command(""":execute 'nnoremap <buffer> <CR> :Python vocabnotebook.show_the_entry()'""")
    # before saving I should clear other entries, making sure only one is left
    # need a if loop to ensure only one entry is left
    if vim.eval("g:vocab_one_entry") == "1":
        #vim.command(":execute 'nnoremap <buffer> s :Python vocabnotebook.dump_to_MySQL(\"" + wd + "\")<cr>'")
        vim.command("autocmd BufWriteCmd d-tmp :Python vocabnotebook.dump_to_MySQL()")
    # TODO multientry dump

def main():
    wd = vim.eval('shellescape(expand("<cword>"))')
    wd = wd.replace("'",'')
    vim.command('normal! ("ayas')
    vim.command("let @\"=substitute(@a,'\n',' ','g')")
    show_in_buffer(wd)

def closedb():
    cur.close()
    con.close()
