import requests
import pdftotext
import pandas
import numpy
import re
import pathlib

root = str(pathlib.Path(__file__).parent.parent.absolute()) + "/"
url_head = "https://www.gstatic.com/covid19/mobility/"
url_tail = "Mobility_Report_en.pdf"


def _process_data_string(line):
    return [
        int(string.strip().split()[0][:-1]) if "baseline" in string else numpy.nan
        for string in line.split("  ")
        if len(string) != 0
    ]


def _identify_subdivision_line(lines):
    leng = len(lines)
    for i in range(2, leng):
        if "Retail" in lines[i]:
            return i - 1
    return -1


def _find_data_lines(lines):
    return [
        _process_data_string(line)
        for line in lines
        if ("compared to baseline" in line or "Not enough data" in line)
    ]


def _list_to_dict(_list):
    return {
        "retail_recreation": _list[0],
        "grocery_pharmacy": _list[1],
        "parks": _list[2],
        "transit_stations": _list[3],
        "workplace": _list[4],
        "residential": _list[5],
    }


def mobility_report_extract(
    country_code, subdivision=None, nation=None, date="2020-03-29"
):
    if subdivision:
        url = (
            url_head
            + date
            + "_"
            + country_code
            + "_"
            + subdivision.replace(" ", "_")
            + "_"
            + url_tail
        )
        top_level_name = subdivision
    else:
        url = url_head + date + "_" + country_code + "_" + url_tail
        top_level_name = country_code
    r = requests.get(url)
    if r.status_code == 200:
        file_path = root + "data/" + top_level_name.replace(" ", "_") + ".pdf"
        with open(file_path, "wb") as f:
            f.write(r.content)
        with open(file_path, "rb") as f:
            pdf = pdftotext.PDF(f)
        leng = len(pdf)
        first = pdf[0]
        second = pdf[1]
        res = []
        top_level_data = []
        pattern = "January|February|March|April|May|June|July|August|September|October|November|December"
        if subdivision:
            nation = str(nation)
        else:
            nation = re.split(pattern, first.split("\n")[1])[0].strip()
        messages = first.split("Mobility trends")[1:]
        for message in messages:
            data = message.split("\n")[1][:-1]
            try:
                data = int(data)
            except ValueError:
                data = numpy.nan
            top_level_data.append(data)
        messages = second.split("Mobility trends")[1:]
        for message in messages:
            data = message.split("\n")[1][:-1]
            try:
                data = int(data)
            except ValueError:
                data = numpy.nan
            top_level_data.append(data)
        top_level_dict = _list_to_dict(top_level_data)
        top_level_dict["second_level_subdivision"] = "None"
        top_level_dict["country_code"] = country_code
        top_level_dict["nation"] = nation
        top_level_dict["first_level_subdivision"] = (
            subdivision if subdivision else "None"
        )
        top_level_dict["jurisdiction"] = (
            subdivision + "," + nation if subdivision else nation
        )
        res.append(top_level_dict)
        for i in range(2, leng - 1):
            lines = pdf[i].split("\n")
            second_sudivision_line_num = _identify_subdivision_line(lines)
            data_res = _find_data_lines(lines)
            data_res[0].extend(data_res[1])
            _dict = _list_to_dict(data_res[0])
            _dict["country_code"] = country_code
            _dict["nation"] = nation
            if subdivision:
                _dict["first_level_subdivision"] = subdivision
                _dict["second_level_subdivision"] = lines[0].strip()
                _dict["jurisdiction"] = (
                    lines[0].strip() + "," + subdivision + "," + nation
                )
            else:
                _dict["first_level_subdivision"] = lines[0].strip()
                _dict["second_level_subdivision"] = "None"
                _dict["jurisdiction"] = lines[0].strip() + "," + nation
            res.append(_dict)
            if second_sudivision_line_num != -1:
                data_res[2].extend(data_res[3])
                _dict = _list_to_dict(data_res[2])
                _dict["country_code"] = country_code
                _dict["nation"] = nation
                if subdivision:
                    _dict["first_level_subdivision"] = subdivision
                    _dict["second_level_subdivision"] = lines[
                        second_sudivision_line_num
                    ].strip()
                    _dict["jurisdiction"] = (
                        lines[second_sudivision_line_num].strip()
                        + ","
                        + subdivision
                        + ","
                        + nation
                    )
                else:
                    _dict["first_level_subdivision"] = lines[
                        second_sudivision_line_num
                    ].strip()
                    _dict["second_level_subdivision"] = "None"
                    _dict["jurisdiction"] = (
                        lines[second_sudivision_line_num].strip() + "," + nation
                    )
                res.append(_dict)
        return res
    else:
        print(f"No data for {top_level_name} on {date}")
        return None


def get_international_data():
    df = pandas.read_csv(root + "data/code.csv", keep_default_na=False)
    code_list = df["Code"].tolist()
    df_international = []
    for code in code_list:
        df_international.append(pandas.DataFrame(mobility_report_extract(code)))
    df_int_final = pandas.concat(df_international)
    df_int_final.to_csv(root + "data/international.csv")


def get_us_data():
    state_list = [
        "Alabama",
        "Alaska",
        "Arizona",
        "Arkansas",
        "California",
        "Colorado",
        "Connecticut",
        "Delaware",
        "District of Columbia",
        "Florida",
        "Georgia",
        "Hawaii",
        "Idaho",
        "Illinois",
        "Indiana",
        "Iowa",
        "Kansas",
        "Kentucky",
        "Louisiana",
        "Maine",
        "Maryland",
        "Massachusetts",
        "Michigan",
        "Minnesota",
        "Mississippi",
        "Missouri",
        "Montana",
        "Nebraska",
        "Nevada",
        "New Hampshire",
        "New Jersey",
        "New Mexico",
        "New York",
        "North Carolina",
        "North Dakota",
        "Ohio",
        "Oklahoma",
        "Oregon",
        "Pennsylvania",
        "Rhode Island",
        "South Carolina",
        "South Dakota",
        "Tennessee",
        "Texas",
        "Utah",
        "Vermont",
        "Virginia",
        "Washington",
        "West Virginia",
        "Wisconsin",
        "Wyoming",
    ]
    df_us = []
    for state in state_list:
        df_us.append(
            pandas.DataFrame(mobility_report_extract("US", state, "United States"))
        )
    df_us_final = pandas.concat(df_us)
    df_us_final.to_csv(root + "data/us.csv")


if __name__ == "__main__":

    get_international_data()
    get_us_data()
