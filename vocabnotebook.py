import vim 
import re
import MySQLdb as mdb
import argparse
from nltk.corpus import wordnet as wn

SHOW_SAVED_MODE = '# Entry Saved'
ALERTS = 'WARNING'

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

if not cur.execute("show tables like 'tags'"):
    cur.execute("""CREATE TABLE tags(
                id SMALLINT,
                word VARCHAR(50),
                tag VARCHAR(80)) ENGINE=InnoDB""")

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
    # for the normal
    if vim.eval("g:word_is_in_db") == "1":
        sql = "UPDATE notebook SET excerpts=%s, sentences=%s WHERE word=%s"
        cur.execute(sql,(wb['definition'], wb['excerpts'], wb['sentences'], wb['word']))
        sql = "DELETE FROM tags WHERE word=%s"
        cur.execute(sql,(wb['word']))
    else:
        sql = "INSERT INTO notebook VALUES(%s,%s,%s)"
        cur.execute(sql,(wb['word'], wb['excerpts'], wb['sentences']))

    sql = "INSERT INTO tag (word,tag) VALUES(%s,%s)"
    for tag in wb['tags']:
        cur.execute(sql,(wb['word'],tag))

    con.commit()
    bwrite(SHOW_SAVED_MODE)

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
        if line == SHOW_SAVED_MODE or re.match("^#", line) or ALERTS in line:
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
        bwrite("Excerpts: "+word_row[0]+vim.eval("t:cssentence"))
        bwrite("Sentences: "+word_row[1])
    elif len(row)==0: 
        bwrite("# No match from database. Do it for yourself by entering t for Tags, s for sentences")
        vim.command("let g:word_is_in_db = 0")

def load_from_wordnet(wd):
    'for details as comments'
    # TODO call a function to show details, including trigering for hyponymy and hypernym etc.
    for i,j in enumerate(wn.synsets(wd)):
        bwrite('# Lemmas: ' + ', '.join([str(lemma.name()) for lemma in wn.synset(j.name()).lemmas()]))
        #bwrite('# Hyponymy: ' + ', '.join([str(lemma.name()) for lemma in wn.synset(j.name()).lemmas()]))
        #bwrite('# Hypernym: ' + ', '.join([str(lemma.name()) for lemma in wn.synset(j.name()).lemmas()]))
        bwrite('\n')


def show_the_entry():
    "clear all entries except the one under the cursor"
    vim.command('"eddggdG')
    vim.command("let g:win_level = 2")
    vim.command("setlocal modifiable")
    vim.command("autocmd BufWriteCmd d-tmp :Python vocabnotebook.dump_to_DB("+extract_entry()+")<CR>")
    target_word = vim.eval("@e").split()[1]
    definition = vim.eval("@e").split()[2]
    load_from_db(target_word, definition)
    vim.command(":execute 'nnoremap <buffer> <CR> :Python vocabnotebook.load_from_wordnet("+target_word+")<CR>'")
    
    print("press :w to dump the entry to mysql")

def show_entries(wd):
    for i,j in enumerate(wn.synsets(wd)):
        w_name = str(j.name())
        bwrite(str(i) + ". " + w_name + " " + str(j.definition()))
    # delete all words except that one the cursor is in
    vim.command(""":execute 'nnoremap <buffer> <CR> :Python vocabnotebook.show_the_entry()<CR>'""")
    # before saving I should clear other entries, making sure only one is left
    # need a if loop to ensure only one entry is left
    # TODO multientry dump and multitimes dump
    vim.command("setlocal nomodifiable")

def main():
    vim.command("call <SID>Init()") 
    print('press p to paste the sentence containing the word to one of the excerpt; press c to clear all other entries')
    wd = vim.eval('t:csword')
    wd = wd.replace("'",'')
    show_entries(wd)

def closedb():
    cur.close()
    con.close()
