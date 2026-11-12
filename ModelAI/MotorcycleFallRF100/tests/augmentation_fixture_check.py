"""Temporary software fixture: never a real motorcycle performance result."""
from pathlib import Path
import tempfile
import sys, json, shutil
import numpy as np
import pandas as pd

SOURCE = Path(__file__).resolve().parents[1]
TEMP = tempfile.TemporaryDirectory(prefix='rf100_augmentation_check_')
ROOT = Path(TEMP.name)/'synthetic_project'
sys.path.insert(0, str(SOURCE))
from rf100.io import write_json, sha256
from rf100.dataset import AugmentedSource
from rf100.pipeline import run

ROOT.mkdir(parents=True, exist_ok=True)
for folder in ['config', 'data/original', 'rf100']:
    (ROOT/folder).mkdir(parents=True, exist_ok=True)
for file in (SOURCE/'rf100').glob('*.py'): shutil.copy2(file, ROOT/'rf100'/file.name)
settings = json.loads((SOURCE/'config/settings.json').read_text())
parents = json.loads((SOURCE/'config/parents.json').read_text())
original = ROOT/'simulation/ORIGINAL/results/ORIGINAL_FIXTURE'
augmented = ROOT/'simulation/AUGMENTED/results/AUGMENT_FIXTURE'
original.mkdir(parents=True, exist_ok=True); augmented.mkdir(parents=True, exist_ok=True)
(augmented.parent/'LATEST_RUN.txt').write_text(augmented.name)
old = np.array([0, 0, 0, 0.7, -0.4, 0.2])
frozen = {'C': {'schema': 2, 'method': 'FULL_RECORD_CONDITIONAL_KINEMATIC_RECONSTRUCTION'},
          'K': {'bias': old.tolist(), 'sensor_to_body': np.eye(3).tolist(),
                'test_values_used': False, 'build_keys': [p['key'] for p in parents if p['generator_split']=='build']},
          'test_values_used_for_common_configuration': False}
write_json(original/'FROZEN_CONFIGURATION.json', frozen)
frozen_hash = sha256(original/'FROZEN_CONFIGURATION.json')
model_hashes = ['%064x' % (i+1) for i in range(10)]
write_json(augmented/'ORIGINAL_RUN.json', {'original_run_name': original.name,
           'frozen_sha256': frozen_hash, 'original_model_sha256': model_hashes})
rng = np.random.default_rng(1024); rows=[]
for i, p in enumerate(parents):
    t = np.arange(600)/100+0.001
    x = np.zeros((600, 6)); x[:, 2]=9.81+0.02*np.sin(2*np.pi*t)
    x[:, 3:] = np.array([0.1, -0.1, 0.05])+0.01*np.sin(t[:, None])
    if p['record_contains_fall']:
        ix = (t>=3)&(t<5)
        x[ix, 3:] += 120*np.sin(np.pi*(t[ix]-3)/2)[:,None]
        x[ix, 0] += 9*np.sin(np.pi*(t[ix]-3)/2)
        p['reference_contact_start_s']=3.0; p['reference_contact_end_s']=3.2
    path = ROOT/p['relative_path']
    np.savetxt(path, np.column_stack([t,x]), delimiter=',', header='Time_s,Ax_m_s2,Ay_m_s2,Az_m_s2,Gx_deg_s,Gy_deg_s,Gz_deg_s', comments='', fmt='%.9f')
    p.update(sha256=sha256(path), samples=len(t), first_time_s=float(t[0]), last_time_s=float(t[-1]))
    w = np.deg2rad(x[:,3:]-old[3:]); alpha=np.gradient(w, 0.01, axis=0)
    for number in range(1,101):
        group = 'bias_only' if number<=34 else ('position_only' if number<=67 else 'bias_and_position')
        bias = rng.uniform(-1,1,6)*np.array([0.1]*3+[0.02]*3) if group!='position_only' else np.zeros(6)
        dr = rng.uniform(-0.05,0.05,3) if group!='bias_only' else np.zeros(3)
        variant=x.copy(); variant[:,:3]+=np.cross(alpha,dr)+np.cross(w,np.cross(w,dr))
        variant+=bias
        directory=augmented/'records'/p['key']/group;directory.mkdir(parents=True,exist_ok=True)
        stem=directory/f'variant_{number:03d}'
        csv=Path(str(stem)+'.csv'); definition=Path(str(stem)+'.json'); complete=Path(str(stem)+'.complete.json')
        np.savetxt(csv,np.column_stack([t,variant]),delimiter=',',header='Time_s,Ax_m_s2,Ay_m_s2,Az_m_s2,Gx_deg_s,Gy_deg_s,Gz_deg_s',comments='',fmt='%.9f')
        write_json(definition,{'parent_key':p['key'],'parent_split':p['generator_split'],
            'record_contains_fall':p['record_contains_fall'],'variant_index':number,'group':group,
            'samples':len(t),'position_delta_body_m':dr,'bias_delta':bias,'bias_total':old+bias,
            'parent_model_sha256':model_hashes[i],'frozen_configuration_sha256':frozen_hash,
            'scope':'SAME_LATENT_MOTION_CONSTANT_BIAS_AND_FIXED_BODY_POSITION',
            'timing_preserved':True,'mounting_rotation_preserved':True,
            'acc_bias_units':'m/s^2','gyro_bias_units':'deg/s'})
        write_json(complete,{'all_outputs_complete':True,'csv_sha256':sha256(csv),'definition_sha256':sha256(definition)})
        rows.append({'ParentKey':p['key'],'ParentSplit':p['generator_split'],
                     'Group':group,'VariantIndex':number,'Materialized':True,'Samples':len(t)})
pd.DataFrame(rows).to_csv(augmented/'VARIANT_MANIFEST.csv',index=False)
write_json(ROOT/'config/parents.json',parents);write_json(ROOT/'config/settings.json',settings)

source = AugmentedSource(ROOT/'simulation',parents,settings)
assert [sum(len(source.rows[p['key']]) for p in parents if p['ai_split']==s) for s in ['train','validation','test']]==[600,200,200]
row=source.rows[parents[0]['key']][0]
original_bytes=row['path'].read_bytes()
with row['path'].open('ab') as f:f.write(b'\n')
try:
    source.definition(row,parents[0])
    raise AssertionError('A changed CSV checksum was not rejected')
except ValueError:pass
row['path'].write_bytes(original_bytes)
table=pd.read_csv(augmented/'VARIANT_MANIFEST.csv');table.loc[0,'Materialized']=False
table.to_csv(augmented/'VARIANT_MANIFEST.csv',index=False)
try:
    AugmentedSource(augmented,parents,settings)
    raise AssertionError('Incomplete export was accepted without permission')
except ValueError:pass
partial=AugmentedSource(augmented,parents,settings,allow_partial=True)
assert sum(map(len,partial.rows.values()))==999
table.loc[0,'Materialized']=True;table.to_csv(augmented/'VARIANT_MANIFEST.csv',index=False)

output=ROOT/'synthetic_results'
if output.exists():shutil.rmtree(output)
run(ROOT,output,ROOT/'simulation')
counts=pd.read_csv(output/'SPLIT_SUMMARY.csv')
assert counts.augmented_available.tolist()==[600,200,200]
audit=pd.read_csv(output/'DATASET_AUDIT.csv')
assert len(audit)==1010 and (audit.ai_split=='train').sum()==606
info=json.loads((output/'BEST_MODEL_INFO.json').read_text())
assert info['trees']==100
metrics=pd.read_csv(output/'EVALUATION_SUMMARY.csv')
assert {'train_augmented_fit_diagnostic','validation_augmented_stress','test_augmented_stress'}.issubset(set(metrics.evaluation))
stages=[json.loads(line)['stage'] for line in (output/'STAGES.jsonl').read_text().splitlines()]
assert stages.index('SELECTION_FROZEN_BEFORE_NUMERIC_REAL_TEST_READ')<stages.index('POST_FREEZE_AUGMENTED_VALIDATION_AND_TEST_STRESS')
write_json(ROOT/'AUGMENTED_SOFTWARE_CHECK.json',{
    'status':'PASS','fixture':'synthetic, not measured model performance',
    'completed_variants':1000,'train_variants':600,'validation_variants':200,'test_variants':200,
    'audited_recordings':1010,'rf_trees':100,'tampered_csv_rejected':True,
    'incomplete_export_rejected':True,'explicit_partial_mode_checked':True,
    'post_freeze_stress_checked':True})
print('SYNTHETIC END-TO-END AUGMENTATION CHECK PASSED',flush=True)

TEMP.cleanup()
