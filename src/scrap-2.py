
# Common imports
import os

# Geovpylib library
import geovpylib.database as db
import geovpylib.utils as u
eta = u.Eta()

# Specific imports
from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By

# Connect to database
db_url_env_var_name = 'YELLOW_SWITZERLAND_AND_BEYOND' # Name of an environment variable holding the Postgres database URL
execute = True # Boolean to prevent to execute directly into databases
db.connect_external(os.getenv(db_url_env_var_name), execute=execute)


browser = Chrome()

persons = db.query('select * from hls.person')

cpt = 0
sql = ""
eta.begin(len(persons), 'Scraping persons notices')
for _, person in persons.iterrows():
    if person['notice']: 
        eta.iter()
        continue
    
    browser.get(person['url'])
    notice = browser.find_element(By.CSS_SELECTOR, '.hls-article-text-unit > p').text

    try:
        birthdate = browser.find_element(By.CSS_SELECTOR, '.hls-article-text-unit > p > .hls-dnais').text
        if birthdate.strip() != '': notice = notice.replace(birthdate, 'Naît le ' + birthdate)
    except: pass

    try:
        deathdate = browser.find_element(By.CSS_SELECTOR, '.hls-article-text-unit > p > .hls-ddec').text
        if birthdate.strip() != '': notice = notice.replace(deathdate, 'meurt le ' + birthdate)
    except: pass

    sql += f"""
        update hls.person
            set notice = '{notice.replace("'", "''")}'
        where id = {person['id']};
    """
    cpt += 1

    if cpt >= 10: 
        db.execute(sql)
        sql = ""
        cpt = 0
    eta.iter()
eta.end()
