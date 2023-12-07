
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

themes = db.query('select * from hls.theme')

cpt = 0
sql = ""
eta.begin(len(themes), 'Scraping themes notices')
for _, theme in themes.iterrows():
    if theme['notice']: 
        eta.iter()
        continue
    
    browser.get(theme['url'])
    notice = browser.find_element(By.CSS_SELECTOR, '.hls-article-text-unit > p').text

    sql += f"""
        update hls.theme
            set notice = '{notice.replace("'", "''")}'
        where id = {theme['id']};
    """
    cpt += 1

    if cpt >= 10: 
        db.execute(sql)
        sql = ""
        cpt = 0
    eta.iter()
eta.end()
