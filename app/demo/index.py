import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from flask import Flask, render_template

from app.demo.pages.attribute import AttributePage
from app.demo.pages.coordinate import CoordinatePage
from app.demo.pages.lookup import LookupPage
from app.demo.pages.region import RegionPage

app = Flask(__name__)

PAGES = [RegionPage, LookupPage, CoordinatePage, AttributePage]

for page in PAGES:
    page.register(app)


@app.route("/")
def index():
    return render_template("index.html", pages=PAGES)


if __name__ == "__main__":
    app.run(debug=True)
