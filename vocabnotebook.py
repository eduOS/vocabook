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
    cur.execute("""CREATE TABLE notebook(\
            id SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
            word VARCHAR(100) NOT NULL, \
            excerpts VARCHAR(50000)), \
            sentences VARCHAR(50000)""")

if not cur.execute("show tables like 'tag'"):
    cur.execute("""CREATE TABLE tag(\
            word_id SMALLINT, \
            tag VARCHAR(100)""")

def dump_to_MySQL(wd):
    # extract the sentence the cursor is in
    vim.command("let @b='Sentence'")
    for i, j in enumerate(wn.synsets(wd)):
        vim.command("let @a='%s'"% j.name)
        vim.command(""":execute '/^\d\{1}\. ' . @a . '/+,/^' . @b . '/s/Tags:\s*(.*)\sDefinition:/\=setreg("d",submatch(1))/n'""")
        sql = "SELECT id FROM notebook WHERE word=%s"
        cur.execute(sql,(j.name))
        wd_id = cur.fetchone()
        sql = "DELETE FROM tag WHERE word_id=%s"
        cur.execute(sql,(wd_id))
        tags = list(set(vim.eval('@d').split(',')))
        if tags:
            sql = "INSERT INTO tag (word_id,tag) VALUES(%s,%s)"
            for tag in tags:
                cur.execute(sql,(wd_id,tag,))
        vim.command(""":execute '/^\d\{1}\. ' . @a . '/+,/^' . @b . '/s/Excerpts:[\s\n]*(.*$)Sentences/\=setreg("d",submatch(1))/n'""")
        excerpts = cur.fetchone()
        vim.command(""":execute '/^\d\{1}\. ' . @a . '/+,/^' . @b . '/s/Sentences:[\s\n]*(.*$)\d.\s/\=setreg("d",submatch(1))/n'""")
        sentences = cur.fetchone()
        sql = "UPDATE notebook SET excerpts=%s, sentences=%s"
        if excerpts or sentences:
            cur.execute(sql,(excerpts,sentences,))
        con.commit()

def bwrite(s):
    b = vim.current.buffer
    # Never write more than two blank lines in a row
    if not s.strip() and not b[-1].strip() and not b[-2].strip():
        return

    if not b[0]:
        b[0] = s
    else:
        b.append(s)

def show_in_buffer(wd):
    bwrite('<---press p to paste the sentence containing the word to one of the excerpt--->')
    vim.command('windo if expand("%")=="d-tmp" |q!|endif')
    vim.command("10sp d-tmp")
    vim.command("setlocal buftype=nofile bufhidden=delete noswapfile")
    for i,j in enumerate(wn.synsets(wd)):
        bwrite(i + ". " + j.name + " Definition: " + j.definition())
        bwrite("Definition: " + j.definition())
        sql = """select tag from tag where word='%s'"""
        cur.execute(sql,(j.name,)):
        rows = cur.fetchall()
        if rows is not None:
            bwrite("Tags: ")
            tags = ",".join(rows)
            bwrite(tags)
        sql = """select excerpts from notebook where word='%s'"""
        cur.execute(sql,(j.name,)):
        rows = cur.fetchall()
        bwrite("Excerpts:")
        if rows is not None:
            bwrite(" ".join(rows))
        sql = """select sentences from notebook where word='%s'"""
        cur.execute(sql,(j.name,)):
        rows = cur.fetchall()
        bwrite("Sentences:")
        if rows is not None:
            bwrite(" ".join(rows))
        bwrite('\n')
    vim.command("normal gg")


def main():
    wd = vim.eval('shellescape(expand("<cword>"))')
    show_in_buffer(wd)
    vim.command('normal! ("ayas')
    vim.command("let @0=substitute(@a,'\n',' ','g')")

def closedb():
    cur.close()
    con.close()
