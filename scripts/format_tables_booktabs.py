# -*- coding: utf-8 -*-
"""
Post-processing script to ensure all standalone Word (.docx) tables in results/
follow the publication-grade Booktabs standard:
- 1.5 pt top and bottom rules, 0.75 pt header underline, no vertical borders
- Pure white background (#FFFFFF)
- Exact column widths in dxa
- Landscape orientation for wide tables (Tables 1 and 2, width = 9.50 in, margins = 0.75 in)
- Portrait orientation for vertical tables (Tables 3 and S1-S4, width = 6.80-6.90 in, margins = 0.80 in)
- Zero table indentation (w:tblInd w:w="0") and centered alignment (w:jc w:val="center")
- cantSplit on all rows and tblHeader on header rows
- Clean variable names in Table S4
"""

import os
import sys
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.section import WD_ORIENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls, qn

def set_page_landscape(section):
    section.orientation = WD_ORIENT.LANDSCAPE
    section.page_width = Inches(11.0)
    section.page_height = Inches(8.5)
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.75)
    section.left_margin = Inches(0.75)
    section.right_margin = Inches(0.75)

def set_page_portrait(section):
    section.orientation = WD_ORIENT.PORTRAIT
    section.page_width = Inches(8.5)
    section.page_height = Inches(11.0)
    section.top_margin = Inches(0.80)
    section.bottom_margin = Inches(0.80)
    section.left_margin = Inches(0.80)
    section.right_margin = Inches(0.80)

def apply_booktabs_to_table(table, col_widths, col_alignments, clean_headers=None):
    col_widths_dxa = [int(w * 1440) for w in col_widths]
    tblPr = table._tbl.tblPr

    # Fixed layout
    tblLayout = tblPr.find(qn('w:tblLayout'))
    if tblLayout is not None:
        tblLayout.set(qn('w:type'), 'fixed')
    else:
        tblPr.append(parse_xml(f'<w:tblLayout {nsdecls("w")} w:type="fixed"/>'))

    # Centered alignment
    jc = tblPr.find(qn('w:jc'))
    if jc is not None:
        jc.set(qn('w:val'), 'center')
    else:
        tblPr.append(parse_xml(f'<w:jc {nsdecls("w")} w:val="center"/>'))

    # Zero indent
    tblInd = tblPr.find(qn('w:tblInd'))
    if tblInd is not None:
        tblInd.set(qn('w:w'), '0')
    else:
        tblPr.append(parse_xml(f'<w:tblInd {nsdecls("w")} w:w="0"/>'))

    # Borders: 1.5pt top/bottom, none inside/vertical
    existing_borders = tblPr.find(qn('w:tblBorders'))
    if existing_borders is not None:
        tblPr.remove(existing_borders)
    borders_xml = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>\n'
        f'  <w:top w:val="single" w:sz="12" w:space="0" w:color="000000"/>\n'
        f'  <w:bottom w:val="single" w:sz="12" w:space="0" w:color="000000"/>\n'
        f'  <w:left w:val="none"/>\n'
        f'  <w:right w:val="none"/>\n'
        f'  <w:insideH w:val="none"/>\n'
        f'  <w:insideV w:val="none"/>\n'
        f'</w:tblBorders>'
    )
    tblPr.append(borders_xml)

    # Cell padding
    tblCellMar = parse_xml(
        f'<w:tblCellMar {nsdecls("w")}>\n'
        f'  <w:top w:w="120" w:type="dxa"/>\n'
        f'  <w:bottom w:w="120" w:type="dxa"/>\n'
        f'  <w:left w:w="150" w:type="dxa"/>\n'
        f'  <w:right w:w="150" w:type="dxa"/>\n'
        f'</w:tblCellMar>'
    )
    existing_mar = tblPr.find(qn('w:tblCellMar'))
    if existing_mar is not None:
        tblPr.remove(existing_mar)
    tblPr.append(tblCellMar)

    # Replace grid with explicit widths
    tblGrid = table._tbl.find(qn('w:tblGrid'))
    if tblGrid is not None:
        table._tbl.remove(tblGrid)
    new_grid = parse_xml(
        f'<w:tblGrid {nsdecls("w")}>\n' +
        '\n'.join([f'  <w:gridCol w:w="{w}"/>' for w in col_widths_dxa]) +
        '\n</w:tblGrid>'
    )
    table._tbl.insert(table._tbl.index(tblPr) + 1, new_grid)

    # Clean headers
    if clean_headers:
        for c_idx, h_text in enumerate(clean_headers):
            if c_idx < len(table.rows[0].cells):
                table.rows[0].cells[c_idx].text = h_text

    # Format rows and cells
    for r_idx, row in enumerate(table.rows):
        trPr = row._tr.get_or_add_trPr()
        if trPr.find(qn('w:cantSplit')) is None:
            trPr.append(parse_xml(f'<w:cantSplit {nsdecls("w")}/>'))
        if r_idx == 0:
            if trPr.find(qn('w:tblHeader')) is None:
                trPr.append(parse_xml(f'<w:tblHeader {nsdecls("w")}/>'))

        for c_idx, cell in enumerate(row.cells):
            tcPr = cell._tc.get_or_add_tcPr()
            tcW = tcPr.find(qn('w:tcW'))
            if tcW is not None:
                tcW.set(qn('w:w'), str(col_widths_dxa[c_idx]))
                tcW.set(qn('w:type'), 'dxa')
            else:
                tcPr.append(parse_xml(f'<w:tcW {nsdecls("w")} w:w="{col_widths_dxa[c_idx]}" w:type="dxa"/>'))

            # Pure white fill
            shd = tcPr.find(qn('w:shd'))
            if shd is not None:
                tcPr.remove(shd)
            tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="FFFFFF" w:val="clear"/>'))

            # Header underline (0.75 pt)
            if r_idx == 0:
                existing_tcB = tcPr.find(qn('w:tcBorders'))
                if existing_tcB is not None:
                    tcPr.remove(existing_tcB)
                tcBorders = parse_xml(
                    f'<w:tcBorders {nsdecls("w")}>\n'
                    f'  <w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/>\n'
                    f'  <w:top w:val="none"/>\n'
                    f'  <w:left w:val="none"/>\n'
                    f'  <w:right w:val="none"/>\n'
                    f'</w:tcBorders>'
                )
                tcPr.append(tcBorders)

            # Cell text typography & alignment
            align = col_alignments[c_idx] if c_idx < len(col_alignments) else 'L'
            align_wd = WD_ALIGN_PARAGRAPH.LEFT
            if align == 'R':
                align_wd = WD_ALIGN_PARAGRAPH.RIGHT
            elif align == 'C':
                align_wd = WD_ALIGN_PARAGRAPH.CENTER

            for p in cell.paragraphs:
                p.alignment = align_wd
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.space_after = Pt(0)
                p.paragraph_format.line_spacing = 1.05
                for run in p.runs:
                    run.font.name = 'Cambria'
                    run.font.color.rgb = RGBColor(0, 0, 0)
                    if r_idx == 0:
                        run.font.size = Pt(10)
                        run.font.bold = True
                    else:
                        run.font.size = Pt(9.5)
                        if cell.text.strip() == 'Random-Effect & Fit Statistics':
                            run.font.bold = True

TABLE_CONFIGS = {
    'Table_1': {
        'landscape': True,
        'headers': ["Variable", "Category", "Sample (n)", "Weighted %", "Stunting % (95% CI)", "Wasting % (95% CI)", "Underweight % (95% CI)"],
        'widths': [1.65, 1.35, 0.80, 0.80, 1.60, 1.60, 1.70],
        'align': ['L', 'L', 'R', 'R', 'C', 'C', 'C']
    },
    'Table_2': {
        'landscape': True,
        'headers': ["Variable", "Stunting \u03c7\u00b2", "df", "p-value", "Wasting \u03c7\u00b2", "df", "p-value", "Underweight \u03c7\u00b2", "df", "p-value"],
        'widths': [2.20, 0.85, 0.45, 0.90, 0.85, 0.45, 0.90, 1.00, 0.45, 0.90],
        'align': ['L', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C']
    },
    'Table_3': {
        'landscape': False,
        'headers': ["Variable", "Category", "Stunting AOR (95% CI)", "Wasting AOR (95% CI)", "Underweight AOR (95% CI)"],
        'widths': [1.50, 1.35, 1.35, 1.35, 1.35],
        'align': ['L', 'L', 'C', 'C', 'C']
    },
    'Table_S1': {
        'landscape': False,
        'headers': ["Variable", "Category", "Model I", "Model II", "Model III"],
        'widths': [1.50, 1.40, 1.30, 1.30, 1.30],
        'align': ['L', 'L', 'C', 'C', 'C']
    },
    'Table_S2': {
        'landscape': False,
        'headers': ["Variable", "Category", "Model I", "Model II", "Model III"],
        'widths': [1.50, 1.40, 1.30, 1.30, 1.30],
        'align': ['L', 'L', 'C', 'C', 'C']
    },
    'Table_S3': {
        'landscape': False,
        'headers': ["Variable", "Category", "Model I", "Model II", "Model III"],
        'widths': [1.50, 1.40, 1.30, 1.30, 1.30],
        'align': ['L', 'L', 'C', 'C', 'C']
    },
    'Table_S4': {
        'landscape': False,
        'headers': ["Variable", "GVIF", "df", "Adjusted GVIF"],
        'widths': [2.50, 1.40, 1.40, 1.50],
        'align': ['L', 'C', 'C', 'C']
    }
}

VIF_NAME_MAP = {
    'Child_Age': 'Child age',
    'Birth_Order': 'Birth order',
    'Mother_Age': "Mother's age",
    'Mother_Education': "Mother's education level",
    'Children_Ever_Born': 'Children ever born',
    'Currently_Pregnant': 'Currently pregnant',
    'Living_Children': 'Number of living children',
    'Wealth_Index': 'Wealth index',
    'Toilet_Facility': 'Toilet facility',
    'Electricity': 'Electricity in household',
    'Owns_TV': 'Owns TV',
    'Owns_Refrigerator': 'Owns refrigerator',
    'Owns_Bicycle': 'Owns Bicycle',
    'Floor_Material': 'Floor material',
    'Wall_Material': 'Wall material',
    'Region': 'Region/Division',
    'Residence': 'Type of residence'
}

def format_directory(target_dir):
    if not os.path.exists(target_dir):
        return
    file_map = {
        'Table_1_Prevalence.docx': 'Table_1',
        'Table_2_Bivariate.docx': 'Table_2',
        'Table_3_Multilevel_Model_III.docx': 'Table_3',
        'Table_S1_Stunting_Multilevel.docx': 'Table_S1',
        'Table_S2_Wasting_Multilevel.docx': 'Table_S2',
        'Table_S3_Underweight_Multilevel.docx': 'Table_S3',
        'Table_S4_Multicollinearity_VIF.docx': 'Table_S4'
    }

    for fname, cfg_key in file_map.items():
        fpath = os.path.join(target_dir, fname)
        if not os.path.exists(fpath):
            continue
        try:
            doc = docx.Document(fpath)
            cfg = TABLE_CONFIGS[cfg_key]
            sec = doc.sections[0]
            if cfg['landscape']:
                set_page_landscape(sec)
            else:
                set_page_portrait(sec)

            if len(doc.tables) > 0:
                tbl = doc.tables[0]
                if cfg_key == 'Table_S4':
                    for row in tbl.rows[1:]:
                        raw_var = row.cells[0].text.strip()
                        if raw_var in VIF_NAME_MAP:
                            row.cells[0].text = VIF_NAME_MAP[raw_var]
                apply_booktabs_to_table(tbl, cfg['widths'], cfg['align'], cfg['headers'])
            doc.save(fpath)
            print(f"  [OK] Formatted: {fname}")
        except Exception as e:
            print(f"  [ERR] {fname}: {e}")

if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.abspath(os.path.join(script_dir, '..'))
    results_dir = os.path.join(base_dir, 'results')
    
    # If custom dir passed via arguments
    if len(sys.argv) > 1 and os.path.isdir(sys.argv[1]):
        results_dir = sys.argv[1]

    print(f"Formatting Booktabs tables in: {results_dir}")
    format_directory(results_dir)
