import vim 
import MySQLdb as mdb
import argparse

con = mdb.connect('localhost','root',"104064")
cur = con.cursor()

if not cur.execute("show databases like 'VocNB'"):
    cur.execute("CREATE DATABASE VocNB")
cur.execute("use VocNB")
if not cur.execute("show tables like 'notebook'"):
    cur.execute("""CREATE TABLE notebook(\
            id SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,\
            word VARCHAR(100) NOT NULL, \
            sentence VARCHAR(5000) NOT NULL)""")

def main():
    wd = vim.eval('shellescape(expand("<cword>"))')
    # extract the sentence the cursor is in
    vim.command('normal! ("ayas')
    vim.command("let @a=substitute(@a,'\n',' ','g')")
    st = vim.eval('@a')
    sql = "INSERT INTO notebook (word,sentence) VALUES(%s,%s)"
    cur.execute(sql,(wd,st,))
    con.commit()

def closedb():
    cur.close()
    con.close()

def supervocab():
    #clear the regester a
    vim.command('normal! qaq')
    vim.command('normal! g/^:s/yank A')
    exasen = vim.eval('@A')[3:]
    exasens = exasen.split('\n')
    vim.command('normal! qbq')
    vim.command('normal! g/^:t/yank B')
    tag = vim.eval('@B')[3:]
    tags = exasen.split(';')
    vim.command('normal! {"cy{')
    defi = vim.eval('@c')

